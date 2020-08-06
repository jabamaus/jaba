# frozen_string_literal: true

# The only ruby library files that Jaba core depends on
require 'digest/sha1'
require 'fileutils'
require 'json'
require 'tsort'

require_relative 'core_ext'
require_relative 'hook'
require_relative 'fsm'
require_relative 'utils'
require_relative 'file_manager'
require_relative 'input_manager'
require_relative 'property'
require_relative 'jdl_object'
require_relative 'jaba_attribute_type'
require_relative 'jaba_attribute_definition_flag'
require_relative 'jaba_attribute_definition'
require_relative 'jaba_attribute'
require_relative 'jaba_attribute_array'
require_relative 'jaba_attribute_hash'
require_relative 'jaba_definition'
require_relative 'jaba_node'
require_relative 'jaba_translator'
require_relative 'jaba_type'
require_relative '../extend/generator'
require_relative '../extend/project'
require_relative '../extend/src'
require_relative '../extend/vsproj'
require_relative '../extend/vcxproj'
require_relative '../extend/workspace'
require_relative '../extend/xcodeproj'

##
#
module JABA

  using JABACoreExt

  @@running_tests = false

  # Maximum length of attribute etc title string.
  #
  MAX_TITLE_CHARS = 100
  
  ##
  #
  def self.running_tests?
    @@running_tests
  end

  ##
  # 
  def self.cwd
    @@cwd ||= Dir.getwd
  end
  
  ##
  #
  def self.jaba_install_dir
    @@jaba_install_dir ||= "#{__dir__}/../../..".cleanpath
  end

  ##
  #
  def self.temp_dir
    '.jaba'
  end

  ##
  #
  def self.log_file
    "#{JABA.temp_dir}/jaba.log"
  end

  ##
  #
  def self.config_file
    "#{JABA.temp_dir}/config.jaba"
  end

  ##
  #
  class Services

    attr_reader :input
    attr_reader :input_manager
    attr_reader :file_manager
    attr_reader :globals
    attr_reader :globals_node

    @@module_ruby_files_loaded = false
    @@module_jaba_files = []

    ##
    #
    def initialize
      @output = {}
      
      @log_msgs = JABA.running_tests? ? nil : [] # Disable logging when running tests
      
      @warnings = []
      @warn_object = nil
      
      @modules_root = "#{JABA.jaba_install_dir}/modules"
      @src_root = nil
      @jdl_files = []
      @jdl_includes = []
      @jdl_file_lookup = {}
      
      @attr_type_defs = []
      @attr_flag_defs = []
      @jaba_type_defs = []
      @default_defs = []
      @instance_defs = []
      @translator_defs = []

      @open_type_defs = []
      @open_instance_defs = []
      @open_translator_defs = []
      @open_shared_defs = []

      @instance_def_lookup = {}
      @shared_def_lookup = {}

      @jaba_attr_types = []
      @jaba_attr_type_lookup = {}
      @jaba_attr_flags = []
      @jaba_attr_flag_lookup = {}
      @top_level_jaba_types = []
      @jaba_type_lookup = {}
      @translators = {}

      @generators = []
      @generator_lookup = {}

      @globals_type_def = nil
      @globals = nil
      @globals_node = nil

      @null_attr_type = JabaAttributeType.new
      @null_nodes = {}
      
      @in_attr_default_block = false

      @top_level_api = JDL_TopLevel.new(self)
      @file_manager = FileManager.new(self)
      @input_manager = InputManager.new(self)
      @input = @input_manager.input
    end

    ##
    #
    def run
      log "Starting Jaba at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}", section: true
      
      duration = JABA.milli_timer do
        JABA.profile(input.profile) do
          do_run

          if !input.barebones?
            log 'Building output...'
            build_jaba_output
          end
        end
      end

      if !input.barebones?
        summary = String.new "Generated #{@generated.size} files, #{@added.size} added, #{@modified.size} modified in #{duration}"
        summary << " [dry run]" if input.dry_run?
        # TODO: verbose mode prints all generated

        log summary
        log "Done! (#{duration})"

        @output[:summary] = summary
      end

      @output[:warnings] = @warnings.uniq # Strip duplicate warnings
      @output
    ensure
      term_log
    end

    ##
    #
    def do_run
      load_module_ruby_files
      create_core_objects
      
      @input_manager.process(phase: 1)

      if !input_manager.cmd_specified?(:genref)
        @src_root = input.src_root

        if @src_root.nil? && !JABA.running_tests?
          if file_manager.exist?(JABA.config_file)
            content = file_manager.read(JABA.config_file, freeze: false)
            if content !~ /src_root "(.*)"/
              jaba_error("Could not read src_root from #{JABA.config_file}")
            end
            @src_root = Regexp.last_match(1)
          end
          if @src_root.nil?
            @src_root = JABA.cwd
          end
        end

        log "src_root=#{@src_root}"
      end

      load_module_jaba_files

      # Prepend globals type definition so globals are processed first, allowing everything else to access them
      #
      @jaba_type_defs.prepend(@globals_type_def)

      # Create JabaTypes and any associated Generators
      #
      @jaba_type_defs.each do |d|
        make_top_level_type(d.id, d)
      end

      # Open top level JabaTypes so more attributes can be added
      #
      @open_type_defs.each do |d|
        tlt = get_top_level_jaba_type(d.id, errline: d.src_loc_raw)
        tlt.eval_jdl(&d.block)
        tlt.open_sub_type_defs.each do |std|
          st = tlt.get_sub_type(std.id)
          st.eval_jdl(&std.block)
        end
      end

      @top_level_jaba_types.each(&:post_create)

      # When an attribute defined in a JabaType will reference a differernt JabaType a dependency on that
      # type is added. JabaTypes are dependency order sorted to ensure that referenced JabaNodes are created
      # before the JabaNode that are referencing it.
      #
      begin
        @top_level_jaba_types.sort_topological!(:dependencies)
      rescue TSort::Cyclic => e
        err_type = e.instance_variable_get(:@err_obj)
        jaba_error("'#{err_type}' contains a cyclic dependency", errline: err_type.definition.src_loc_raw)
      end

      log 'Initialisation of JabaTypes complete'

      # Now that the JabaTypes are dependency sorted build generator list from them, so they are in dependency order too
      #
      @generators = @top_level_jaba_types.map(&:generator)

      # Process instance definitions and assign them to a generator
      #
      @instance_defs.each do |d|
        jt = get_top_level_jaba_type(d.jaba_type_id, errline: d.src_loc_raw)
        jt.generator.register_instance_definition(d)
      end

      # Register instance open defs
      #
      @open_instance_defs.each do |d|
        inst_def = get_instance_definition(d.instance_variable_get(:@jaba_type_id), d.id, errline: d.src_loc_raw)
        inst_def.add_open_def(d)
      end

      # Create translators
      #
      @translator_defs.each do |d|
        t = Translator.new(d)
        @translators[d.id] = t
      end

      # Register translator open defs
      #
      @open_translator_defs.each do |d|
        t = get_translator(d.id)
        t.definition.add_open_def(d)
      end

      # Register shared definition open blocks
      #
      @open_shared_defs.each do |d|
        sd = get_shared_definition(d.id)
        sd.add_open_def(d)
      end

      # Globals generator is the first one. Remove it as it is handled explicitly.
      #
      globals_generator = @generators.shift
      globals_generator.process
      @globals_node = globals_generator.root_nodes.first
      @globals = @globals_node.attrs

      @input_manager.process(phase: 2)

      if input_manager.cmd_specified?(:genref)
        @top_level_jaba_types.sort_by! {|jt| jt.defn_id}
        generate_reference_doc
        return
      end
      
      # Process generators
      #
      @generators.each do |g|
        g.process

        # Handle singletons
        #
        if g.top_level_jaba_type.singleton
          if g.root_nodes.size == 0
            jaba_error("singleton type '#{g.type_id}' must be instantiated exactly once", errline: g.top_level_jaba_type.definition.src_loc_raw)
          elsif g.root_nodes.size > 1
            jaba_error("singleton type '#{g.type_id}' must be instantiated exactly once", errline: g.root_nodes.last.definition.src_loc_raw)
          end
          
          # Generate acceessor
          #
          define_singleton_method "#{g.type_id}_singleton".to_sym do
            g.root_nodes.first
          end
        end
      end

      # Output definition input data as a json file, before generation. This is raw data as generated from the definitions.
      # Can be used for debugging and testing.
      #
      if globals.dump_input
        dump_jaba_input
      end

      log 'Performing file generation...'

      # Write final files
      #
      @generators.each(&:perform_generation)
    end
    
    ##
    #
    def create_core_objects
      constants = JABA.constants(false) # Don't iterate directly as constants get created inside loop
      constants.each do |c|
        case c
        when /^JabaAttributeType./
          make_attr_type(JABA.const_get(c))
        when /^JabaAttributeDefinitionFlag./
          make_attr_flag(JABA.const_get(c))
        when /^(.+)Generator$/
          # Create non-default generators up front (eg CppGenerator, WorkspaceGenerator). There will only be one instance
          # of each of these. DefaultGenerators will be created later as there will be one created for each jaba type that
          # has not defined its own generator. Creating generators up front allows generators to register early with the
          # system.
          #
          next if c == :DefaultGenerator
          id = Regexp.last_match(1)
          klass = JABA.const_get(c)
          g = klass.new(self)
          g.register
          @generator_lookup[id] = g
        end
      end
      @jaba_attr_types.sort_by!(&:id)
      @jaba_attr_flags.sort_by!(&:id)
    end

    ##
    #
    def make_attr_type(klass)
      at = klass.new
      if @jaba_attr_type_lookup.has_key?(at.id)
        jaba_error("Attribute type multiply defined [id=#{at.id}, class=#{klass}]")
      end
      at.instance_variable_set(:@services, self)
      @jaba_attr_types << at
      @jaba_attr_type_lookup[at.id] = at
      at
    end

    ##
    #
    def make_attr_flag(klass)
      af = klass.new
      if @jaba_attr_flag_lookup.has_key?(af.id)
        jaba_error("Attribute flag multiply defined [id=#{af.id}, class=#{klass}]")
      end
      af.instance_variable_set(:@services, self)
      @jaba_attr_flags << af
      @jaba_attr_flag_lookup[af.id] = af
      af
    end

    ##
    #
    def make_definition(id, block, call_loc)
      JabaDefinition.new(self, id, block, call_loc)
    end

    ##
    #
    def make_top_level_type(handle, definition)
      log "Instancing top level JabaType [handle=#{handle}]"

      if @jaba_type_lookup.key?(handle)
        jaba_error("'#{handle}' jaba type multiply defined")
      end

      generator_id = definition.id.to_s.capitalize_first
      generator = @generator_lookup[generator_id]
      if generator.nil?
        generator = DefaultGenerator.new(self)
      end

      tlt = TopLevelJabaType.new(definition, handle, generator)
      generator.set_top_level_type(tlt)
      generator.init

      @top_level_jaba_types  << tlt
      @jaba_type_lookup[handle] = tlt

      tlt
    end

    ##
    #
    def get_top_level_jaba_type(id, fail_if_not_found: true, errline: nil)
      jt = @jaba_type_lookup[id]
      if !jt && fail_if_not_found
        jaba_error("'#{id}' type not defined", errline: errline)
      end
      jt
    end

    ##
    #
    def validate_id(id)
      if !(id.symbol? || id.string?) || id !~ /^[a-zA-Z0-9_\-.]+$/
        jaba_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
          "(-_. permitted), eg :my_id, 'my-id', 'my.id'")
      end
    end

    ##
    #
    def get_attribute_type(id)
      if id.nil?
        return @null_attr_type
      end
      t = @jaba_attr_type_lookup[id]
      if !t
        jaba_error("'#{id}' attribute type is undefined. Valid types: [#{@jaba_attr_types.map{|at| at.id.inspect}.join(', ')}]")
      end
      t
    end

    ##
    #
    def get_attribute_flag(id)
      f = @jaba_attr_flag_lookup[id]
      if !f
        jaba_error("'#{id.inspect_unquoted}' is an invalid flag. Valid flags: [#{@jaba_attr_flags.map{|at| at.id.inspect}.join(', ')}]")
      end
      f
    end

    ##
    #
    def define_type(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Defining type [id=#{id}]"
      validate_id(id)
      existing = @jaba_type_defs.find{|d| d.id == id}
      if existing
        jaba_error("Type '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_describe}.")
      end
      d = make_definition(id, block, caller_locations(2, 1)[0])
      if id == :globals
        @globals_type_def = d
      else
        @jaba_type_defs << d
      end
      nil
    end
    
    ##
    #
    def define_shared(id, &block)
      jaba_error("id is required") if id.nil?
      jaba_error("A block is required") if !block_given?

      log "  Defining shared definition [id=#{id}]"
      validate_id(id)

      existing = get_shared_definition(id, fail_if_not_found: false)
      if existing
        jaba_error("Shared definition '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_describe}.")
      end

      @shared_def_lookup[id] = make_definition(id, block, caller_locations(2, 1)[0])
      nil
    end

    ##
    #
    def get_shared_definition(id, fail_if_not_found: true)
      d = @shared_def_lookup[id]
      if !d && fail_if_not_found
        jaba_error("Shared definition '#{id}' not found")
      end
      d
    end

    ##
    #
    def define_instance(type_id, id, &block)
      jaba_error("type_id is required") if type_id.nil?
      jaba_error("id is required") if id.nil?

      validate_id(id)

      log "  Defining instance [id=#{id}, type=#{type_id}]"

      existing = get_instance_definition(type_id, id, fail_if_not_found: false)
      if existing
        jaba_error("Type instance '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_describe}.")
      end
      
      d = JabaInstanceDefinition.new(self, id, type_id, block, caller_locations(2, 1)[0])
      @instance_def_lookup.push_value(type_id, d)
      @instance_defs << d
      nil
    end
    
    ##
    #
    def get_instance_definition(type_id, id, fail_if_not_found: true, errline: nil)
      defs = @instance_def_lookup[type_id]
      d = defs&.find {|dd| dd.id == id}
      if !d && fail_if_not_found
        jaba_error("'#{id}' instance not defined", errline: errline)
      end
      d
    end

    ##
    #
    def get_instance_ids(type_id)
      defs = @instance_def_lookup[type_id]
      if !defs
        jaba_error("No '#{type_id}' type defined")
      end
      defs.map(&:id)
    end

    ##
    #
    def define_defaults(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Defining defaults [id=#{id}]"
      existing = @default_defs.find {|d| d.id == id}
      if existing
        jaba_error("Defaults block '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_describe}.")
      end
      @default_defs << make_definition(id, block, caller_locations(2, 1)[0])
      nil
    end

    ##
    #
    def get_defaults_definition(id)
      @default_defs.find {|d| d.id == id}
    end

    ##
    #
    def in_attr_default_block?
      @in_attr_default_block
    end

    ##
    #
    def execute_attr_default_block(node, default_block)
      @in_attr_default_block = true
      result = nil
      node.make_read_only do # default blocks should not attempt to set another attribute
        result = node.eval_jdl(&default_block)
      end
      @in_attr_default_block = false
      result
    end

    ##
    #
    def define_translator(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Defining translator [id=#{id}]"
      existing = @translator_defs.find {|d| d.id == id}
      if existing
        jaba_error("Translator block '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_describe}.")
      end
      @translator_defs << make_definition(id, block, caller_locations(2, 1)[0])
      nil
    end

    ##
    #
    def get_translator(id, fail_if_not_found: true)
      t = @translators[id]
      if !t && fail_if_not_found
        jaba_error("'#{id.inspect_unquoted}' translator not found")
      end
      t
    end

    ##
    #
    def open(what, id, type=nil, &block)
      jaba_error("id is required") if id.nil?
      jaba_error("A block is required") if !block_given?
      call_loc = caller_locations(2, 1)[0]

      case what
      when :type
        log "  Opening type [id=#{id}]"
        @open_type_defs << make_definition(id, block, call_loc)
      when :instance
        log "  Opening instance [id=#{id} type=#{type}]"
        jaba_error("type is required") if type.nil?
        d = make_definition(id, block, call_loc)
        d.instance_variable_set(:@jaba_type_id, type)
        @open_instance_defs << d
      when :translator
        log "  Opening translator [id=#{id}]"
        @open_translator_defs << make_definition(id, block, call_loc)
      when :shared
        log "  Opening shared definition [id=#{id}]"
        @open_shared_defs << make_definition(id, block, call_loc)
      end
      nil
    end

    ##
    #
    def get_generator(top_level_type_id)
      g = @generators.find {|g| g.type_id == top_level_type_id}
      jaba_error("'#{top_level_type_id.inspect_unquoted}' generator not found") if !g
      g
    end

    ##
    #
    def get_null_node(type_id)
      nn = @null_nodes[type_id]
      if !nn
        jt = get_top_level_jaba_type(type_id)
        nn = JabaNode.new(jt.definition, jt, "Null#{jt.defn_id}", nil, 0)
        @null_nodes[type_id] = nn
      end
      nn
    end

    ##
    #
    def dump_jaba_input
      root = {}
      root[:jdl_files] = @jdl_files

      @generators.each do |g|
        g_root = {}
        root[g.type_id] = g_root
        g.root_nodes.each do |rn|
          obj = {}
          g_root[rn.handle] = obj
          write_node_json(rn, obj)
        end
      end
      json = JSON.pretty_generate(root)
      file = @file_manager.new_file(globals.jaba_input_file.to_absolute(clean: true), eol: :native, track: false)
      w = file.writer
      w.write_raw(json)
      file.write
    end

    ##
    #
    def write_node_json(node, obj)
      node.visit_attr(top_level: true) do |attr, val|
        obj[attr.defn_id] = val
      end
      if !node.children.empty?
        children = {}
        obj[:children] = children
        node.children.each do |child|
          child_obj = {}
          children[child.handle] = child_obj
          write_node_json(child, child_obj)
        end
      end
    end

    ##
    #
    def build_jaba_output
      out_file = globals.jaba_output_file.to_absolute(clean: true)
      out_dir = out_file.dirname

      @generated = @file_manager.generated.map{|f| f.relative_path_from(out_dir)}

      @output[:version] = '1.0'
      @output[:generated] = @generated

      @generators.each do |g|
        next if g.is_a?(DefaultGenerator)
        g_root = {}
        g.build_jaba_output(g_root, out_dir)
        if !g_root.empty?
          @output[g.type_id] = g_root
        end
      end

      if globals.dump_output && !input_manager.cmd_specified?(:genref)
        json = JSON.pretty_generate(@output)
        file = @file_manager.new_file(out_file, eol: :native)
        w = file.writer
        w.write_raw(json)
        file.write
      end

      # Include all generated files for the purpose of reporting back to the user.
      #
      @file_manager.include_untracked

      # Now make files that will be reported back to the user relative to cwd
      #
      @generated = @file_manager.generated.map{|f| f.relative_path_from(input.dest_root)}
      @added = @file_manager.added.map{|f| f.relative_path_from(input.dest_root)}.sort_no_case!
      @modified = @file_manager.modified.map{|f| f.relative_path_from(input.dest_root)}.sort_no_case!

      # These are not included in the output file but are returned to outer context
      #
      @output[:added] = @added
      @output[:modified] = @modified
    end

    ##
    #
    def include_jdl_file(filename)
      if !filename.absolute_path?
        call_loc = caller_locations(2, 1)[0]
        filename = "#{call_loc.absolute_path.dirname}/#{filename}"
      end
      @jdl_includes << filename
    end

    ##
    # This will cause a series of calls to eg define_attr_type, define_type, define_instance (see further
    # down in this file). These calls will come from user definitions via the api files.
    #
    def execute_jdl(file: nil, str: nil, &block)
      log "Executing #{file}" if file
      if str
        @top_level_api.instance_eval(str, file)
      elsif file
        @top_level_api.instance_eval(file_manager.read(file), file)
      end
      if block_given?
        @top_level_api.instance_eval(&block)
      end
    rescue JDLError
      raise # Prevent fallthrough to next case
    rescue StandardError => e # Catches errors like invalid constants
      jaba_error(e.message, callstack: e.backtrace, include_api: true)
    rescue ScriptError => e # Catches syntax errors. In this case there is no backtrace.
      jaba_error(e.message, syntax: true)
    end

    ##
    #
    def load_module_ruby_files
      # Only loaded once in a given process even if jaba invoked multiple times. Helps with effiency of tests.
      #
      return if @@module_ruby_files_loaded
      @@module_ruby_files_loaded = true
      plugin_files = []

      Dir.glob("#{@modules_root}/**/*").each do |f|
        case f.extname
        when '.rb'
          plugin_files << f
        when '.jaba'
          @@module_jaba_files << f
        end
      end
      plugin_files.each do |f|
        require f
      end
    end

    ##
    #
    def load_module_jaba_files
      if input.barebones?
        process_jdl_file("#{@modules_root}/core/globals.jaba") # globals always needs loading
      else
        @@module_jaba_files.each do |f|
          process_jdl_file(f)
        end
      end

      if File.exist?(JABA.config_file) && !JABA.running_tests?
        process_jdl_file(JABA.config_file)
      end

      if @src_root
        process_load_path(@src_root, fail_if_empty: true)
      end

      # Definitions can also be provided in a block form
      #
      Array(input.definitions).each do |block|
        @jdl_files << block.source_location[0]
        execute_jdl(&block)
      end

      # Process include directives, accounting for included files including other files.
      #
      while !@jdl_includes.empty?
        last = @jdl_includes.pop
        process_load_path(last)
      end
    end

    ##
    #
    def process_load_path(p, fail_if_empty: false)
      p = p.to_absolute(clean: true)

      if !File.exist?(p)
        jaba_error("#{p} does not exist")
      end

      if File.directory?(p)
        files = @file_manager.glob("#{p}/*.jaba")
        if files.empty?
          if fail_if_empty
            jaba_error("No .jaba files found in #{p}")
          else
            jaba_warning("No .jaba files found in #{p}")
          end
        else
          files.each do |f|
            process_jdl_file(f)
          end
        end
      else
        process_jdl_file(p)
      end
    end

    ##
    #
    def process_jdl_file(f)
      # TODO: warn on dupes
      # TODO: convert to absolute here?
      if @jdl_file_lookup.has_key?(f)
        jaba_error("'#{f}' multiply included")
      end
      @jdl_file_lookup[f] = nil
      @jdl_files << f

      # Special handling for config.jaba
      #
      if f.basename == 'config.jaba'
        content = @file_manager.read(f, freeze: false)
        log "Executing #{f}"
        content.prepend("open_instance :globals, type: :globals do\n")
        content << "end"
        execute_jdl(file: f, str: content)
      else
        execute_jdl(file: f)
      end
    end

    ##
    #
    def log(msg, severity = :INFO, section: false)
      return if !@log_msgs
      line = msg
      if section
        n = ((130 - msg.size)/2).round # TODO: handle overflow
        line = "#{'=' * n} #{msg} #{'=' * n}"
      end
      @log_msgs << "#{severity} #{line}"
    end

    ##
    #
    def log_warning(msg, **options)
      log(msg, :WARN, **options)
    end

    ##
    #
    def term_log
      return if !@log_msgs
      log_fn = JABA.log_file
      if File.exist?(log_fn)
        File.delete(log_fn)
      else
        FileUtils.makedirs(log_fn.dirname)
      end
      IO.write(log_fn, @log_msgs.join("\n"))
    end

    ##
    #
    def set_warn_object(wo)
      @warn_object = wo
      if block_given?
        yield
        @warn_object = nil
      end
    end

    ##
    #
    def jaba_warning(msg, **options)
      log_warning(msg)
      if @warn_object
        options[:callstack] = @warn_object.is_a?(JDL_Object) ? @warn_object.definition.src_loc_raw : @warn_object
      end
      @warnings << make_jaba_error(msg, warn: true, **options).message
      nil
    end
    
    ##
    #
    def jaba_error(msg, **options)
      log msg, :ERROR
      raise make_jaba_error(msg, **options)
    end

    ##
    # Errors can be raised in 3 contexts:
    #
    # 1) Syntax errors/other ruby errors that are raised by the initial evaluation of the definition files or block in
    #    execute_jdl.
    # 2) From user definitions using the 'fail' API.
    # 3) From core library code. 
    #
    def make_jaba_error(msg, syntax: false, callstack: nil, errline: nil, warn: false, include_api: false)
      error_line = nil

      if syntax
        # With ruby ScriptErrors there is no useful callstack. The error location is in the msg itself.
        #
        error_line = msg

        # Delete ruby's way of reporting syntax errors in favour of our own
        #
        msg = msg.sub(/^.* syntax error, /, '')
      else
        # Clean up callstack which could be in 'caller' form or 'caller_locations' form.
        #
        backtrace = Array(errline || callstack || caller).map do |l|
          if l.is_a?(::Thread::Backtrace::Location)
            "#{l.absolute_path}:#{l.lineno}"
          else
            l
          end
        end

        files = include_api ? @jdl_files + $LOADED_FEATURES.select{|f| f =~ /jaba\/lib\/jaba\/jdl_api/} : @jdl_files

        # Extract any lines in the callstack that contain references to definition source files.
        #
        lines = backtrace.select {|c| files.any? {|sf| c.include?(sf)}}

        # remove the unwanted ':in ...' suffix from user level definition errors
        #
        lines.map!{|l| l.sub(/:in .*/, '')}
        
        # There was nothing in the callstack linking the error to a JDL line. This could be because
        # there is an internal error in jaba, or because the error was not raised properly (ie the
        # context of the error was not passed in the 'callstack' option. Assume the former.
        #
        if lines.empty?
          if warn
            msg = "Warning: #{msg}"
          end
          e = RuntimeError.new(msg)
          e.set_backtrace(backtrace)
          return e
        end
        
        error_line = lines[0]
      end

      # Extract file and line information from the error line.
      #
      if error_line !~ /^(.+):(\d+)/
        raise "Could not extract file and line number from '#{error_line}'"
      end

      file = Regexp.last_match(1)
      line = Regexp.last_match(2).to_i
      m = String.new
      
      m << if warn
             'Warning'
           elsif syntax
             'Syntax error'
           else
             'Error'
           end
      
      m << ' at'
      m << " #{file.basename}:#{line}"
      m << ": #{msg}"
      m.ensure_end_with!('.')
      
      e = JDLError.new(m)
      e.instance_variable_set(:@raw_message, msg)
      e.instance_variable_set(:@file, file)
      e.instance_variable_set(:@line, line)
      e.set_backtrace(lines.uniq) if lines # Can contain unhelpful duplicates due to loops, make unique.
      e
    end

    ##
    #
    def generate_reference_doc
      @docs_dir = "#{JABA.jaba_install_dir}/docs"
      main_page = @file_manager.new_file("#{@docs_dir}/src/jaba_reference.md", capacity: 16 * 1024)
      w = main_page.writer
      w << "# Jaba Definition Language Reference"
      w << ""

      w << "- Attribute variants"
      w << "  - single"
      w << "  - array"
      w << "  - hash"

      w << "- Attribute types"
      @jaba_attr_types.each do |at|
        w << "  - #{at.id}"
      end

      w << "- Attribute flags"
      @jaba_attr_flags.each do |af|
        w << "  - #{af.id}"
      end
      
      w << "- Types"
      @top_level_jaba_types.each do |jt|
        w << "  - [#{jt.defn_id}](#{jt.reference_manual_page})"
        jt.all_attr_defs_sorted.each do |ad|
          w << "    - [#{ad.defn_id}](#{jt.reference_manual_page}##{ad.defn_id})"
        end
      end

      w.newline
      @top_level_jaba_types.each do |jt|
        generate_jaba_type_reference(jt)
      end
      main_page.write
    end

    ##
    #
    def generate_jaba_type_reference(jt)
      file = @file_manager.new_file("#{@docs_dir}/src/#{jt.reference_manual_page(ext: '.md')}", capacity: 16 * 1024)
      w = file.writer
      w << "## #{jt.defn_id}"
      w << "> "
      w << "> _#{jt.title}_"
      w << "> "
      w << "> | Property | Value  |"
      w << "> |-|-|"
      md_row(w, :src, "$(jaba_install)/#{jt.definition.src_loc_describe(style: :rel_jaba_root)}")
      md_row(w, :notes, jt.notes.make_sentence)
      w << "> "
      w << ""
      jt.all_attr_defs_sorted.each do |ad|
        w << "<a id=\"#{ad.defn_id}\"></a>" # anchor for the attribute eg cpp-src
        w << "#### #{ad.defn_id}"
        w << "> _#{ad.title}_"
        w << "> "
        w << "> | Property | Value  |"
        w << "> |-|-|"
        # TODO: need to flag whether per-project/per-config etc
        type = String.new
        if ad.type_id
          type << "#{ad.type_id}"
          type << " #{ad.variant}" if !ad.single?
        end
        md_row(w, :type, type)
        ad.jaba_attr_type.get_reference_manual_rows(ad)&.each do |id, value|
          md_row(w, id, value)
        end
        md_row(w, :default, ad.default.proc? ? nil : ad.default.inspect)
        md_row(w, :flags, ad.flags.map(&:inspect).join(', '))
        md_row(w, :options, ad.flag_options.map(&:inspect).join(', '))
        md_row(w, :src, "$(jaba_install)/#{ad.definition.src_loc_describe(style: :rel_jaba_root)}")
        # TODO: make $(cpp#src_ext) links work again
        md_row(w, :notes, ad.notes.make_sentence.to_markdown_links) if !ad.notes.empty?
        w << ">"
        if !ad.examples.empty?
          w << "> *Examples*"
          w << ">```ruby"
          ad.examples.each do |e|
            e.split_and_trim_leading_whitespace do |line|
              w << "> #{line}"
            end
          end
          w << ">```"
        end
      end
      file.write
    end

    ##
    #
    def md_row(w, p, v)
      w << "> | _#{p}_ | #{v} |"
    end

  end

end
