# frozen_string_literal: true

# The only ruby library files that Jaba core depends on
require 'digest/sha1'
require 'json'
require 'fileutils'
require 'tsort'

require_relative 'core_ext'
require_relative 'utils'
require_relative 'file_manager'
require_relative 'input_manager'
require_relative 'standard_paths'
require_relative 'jaba_object'
require_relative 'jaba_attribute_type'
require_relative 'jaba_attribute_definition_flag'
require_relative 'jaba_attribute_definition'
require_relative 'jaba_attribute'
require_relative 'jaba_attribute_array'
require_relative 'jaba_attribute_hash'
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
require_relative '../extend/ninjaproj'

##
#
module JABA

  using JABACoreExt

  @@running_tests = false

  ##
  #
  def self.running_tests?
    @@running_tests
  end

  ##
  #
  def self.error(msg, errobj: nil, callstack: nil, include_api: false, syntax: false, want_backtrace: true)
    e = JabaError.new(msg)
    e.instance_variable_set(:@callstack, Array(errobj&.src_loc || callstack || caller))
    e.instance_variable_set(:@include_api, include_api)
    e.instance_variable_set(:@syntax, syntax)
    e.instance_variable_set(:@want_backtrace, want_backtrace)
    raise e
  end

  ##
  #
  class Services

    attr_reader :invoking_dir
    attr_reader :input
    attr_reader :output
    attr_reader :input_manager
    attr_reader :file_manager
    attr_reader :globals
    attr_reader :globals_node
    attr_reader :jaba_attr_types
    attr_reader :jaba_temp_dir
    attr_reader :config_file

    @@module_ruby_files_loaded = false
    @@module_jaba_files = []

    ##
    #
    def initialize
      @invoking_dir = Dir.getwd.freeze

      @input = Input.new
      @input.instance_variable_set(:@build_root, nil)
      @input.instance_variable_set(:@src_root, nil)
      @input.instance_variable_set(:@definitions, [])
      @input.instance_variable_set(:@cmd, nil)
      @input.instance_variable_set(:@global_attrs, {})

      @output = {}
      @output[:services] = self # internal access for unit testing
      
      @log_msgs = JABA.running_tests? ? nil : [] # Disable logging when running tests
      
      @warnings = []
      
      @jdl_files = []
      @jdl_includes = []
      @jdl_file_lookup = {}
      @config_loaded = false
      
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

      @null_attr_type = JabaAttributeType.new(:null, 'Null attribute type')
      @null_nodes = {}
      
      @in_attr_default_block = false

      @top_level_api = JDL_TopLevel.new(self)
      @file_manager = FileManager.new(self)
      @input_manager = InputManager.new(self)
    end

    ##
    #
    def execute
      begin
        yield
      rescue => e
        log e.full_message(highlight: false), :ERROR

        case e
        when JabaError
          cs = e.instance_variable_get(:@callstack)
          include_api = e.instance_variable_get(:@include_api)
          err_type = e.instance_variable_get(:@syntax) ? :syntax : :error
          want_backtrace = e.instance_variable_get(:@want_backtrace)
          
          bt = if err_type == :syntax
            [] # Syntax errors (ruby ScriptErrors) don't have backtraces
          else
            jdl_bt = get_jdl_backtrace(cs, include_api: include_api)
            if jdl_bt.empty?
              @output[:error] = want_backtrace ? e.full_message(highlight: !JABA.running_tests?) : e.message
              raise
            end
            jdl_bt
          end

          info = jdl_error_info(e.message, bt, err_type: err_type)
          @output[:error] = want_backtrace ? info.full_message : info.message

          e = JabaError.new(info.message)
          e.instance_variable_set(:@file, info.file)
          e.instance_variable_set(:@line, info.line)
          e.set_backtrace(bt)
          raise e
        else
          @output[:error] = e.full_message(highlight: !JABA.running_tests?)
          raise
        end
      ensure
        term_log
      end
    end

    ##
    #
    def run
      log "Starting Jaba at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}", section: true
      
      duration = JABA.milli_timer do
        @input_manager.process
        
        profile(input.profile) do
          do_run
          build_jaba_output
        end
      end

      summary = "Generated #{@generated.size} files, #{@added.size} added, #{@modified.size} modified in #{duration}"
      summary << " [dry run]" if input.dry_run?
      # TODO: verbose mode prints all generated

      log summary
      log "Done! (#{duration})"

      @output[:summary] = summary
      @output[:warnings] = @warnings.uniq # Strip duplicate warnings
      @output
    end

    ##
    #
    def do_run
      if input_manager.cmd_specified?(:help)
        if OS.windows?
          system("start #{JABA.jaba_docs_url}/v#{VERSION}")
        elsif OS.mac?
          system("open #{JABA.jaba_docs_url}v#{VERSION}")
        end
        exit!
      end
      
      load_module_ruby_files
      create_core_objects

      @input_manager.process_cmd_line
      @input_manager.finalise

      init_root_paths
      load_jaba_files

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
        tlt = get_top_level_jaba_type(d.id, errobj: d)
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
      @top_level_jaba_types.sort_topological!(:dependencies)

      log 'Initialisation of JabaTypes complete'

      # Now that the JabaTypes are dependency sorted build generator list from them, so they are in dependency order too
      #
      @generators = @top_level_jaba_types.map(&:generator)

      # Process instance definitions and assign them to a generator
      #
      @instance_defs.each do |d|
        jt = get_top_level_jaba_type(d.jaba_type_id, errobj: d)
        jt.generator.register_instance_definition(d)
      end

      # Register instance open defs
      #
      @open_instance_defs.each do |d|
        inst_def = get_instance_definition(d.jaba_type_id, d.id, errobj: d)
        inst_def.open_defs << d
      end

      # Register translator open defs
      #
      @open_translator_defs.each do |d|
        tdef = get_translator_definition(d.id)
        tdef.open_defs << d
      end

      # Create translators
      #
      @translator_defs.each do |d|
        t = Translator.new(self, d.id, d.src_loc, d.block)
        @translators[d.id] = t
      end

      # Register shared definition open blocks
      #
      @open_shared_defs.each do |d|
        sd = get_shared_definition(d.id)
        sd.open_defs << d
      end

      # Globals can be set via the command line so need to partition generators into those up to and
      # including the globals type and the rest, processing the command line in between.
      #
      globals_generator = nil
      globals_and_deps, post_globals = @generators.partition do |g|
        if !globals_generator
          if g.type_id == :globals
            globals_generator = g
          end
          true
        else
          false
        end
      end

      globals_and_deps.each do |g|
        g.process
      end

      @globals_node = globals_generator.root_nodes.first
      @globals = @globals_node.attrs

      set_global_attrs_from_cmdline
      process_config_file if !JABA.running_tests?

      post_globals.each do |g|
        g.process
      end

      # Output definition input data as a json file, before generation. This is raw data as generated from the definitions.
      # Can be used for debugging and testing.
      #
      if input.dump_state
        dump_jaba_state
      end

      log 'Performing file generation...'

      # Write final files
      #
      @generators.each(&:perform_generation)
    end
    
    ##
    #
    def init_root_paths
      # Initialise build_root from command line, if not present defaults to cwd. 
      #
      input.build_root = if input.build_root.nil?
        @invoking_dir
      else
        input.build_root.to_absolute(base: @invoking_dir, clean: true)
      end

      @jaba_temp_dir = "#{input.build_root}/.jaba"
      @config_file = "#{@jaba_temp_dir}/config.jaba"

      # Ensure build_root and temp dir exists
      #
      if !File.exist?(@jaba_temp_dir)
        FileUtils.makedirs(@jaba_temp_dir)
      end

      # Jaba may have been invoked from an out-of-source build tree so read src_root from jaba temp dir
      # 
      cached_src_root = nil
      src_root_cache = "#{@jaba_temp_dir}/src_root.cache"
      if File.exist?(src_root_cache)
        str = @file_manager.read(src_root_cache)
        cached_src_root = str[/src_root=(.*)/, 1]
        if cached_src_root && input.src_root && input.src_root != cached_src_root
          JABA.error("Source root already set to '#{cached_src_root}' - cannot change", want_backtrace: false)
        end
        input.src_root = cached_src_root
      end

      input.src_root = if input.src_root.nil?
        @invoking_dir if !JABA.running_tests?
      else
        input.src_root.to_absolute(base: @invoking_dir, clean: true)
      end

      if input.src_root
        if !File.exist?(input.src_root)
          JABA.error("source root '#{input.src_root}' does not exist", want_backtrace: false)
        end

        IO.write(src_root_cache, "src_root=#{input.src_root}")
      end
  
      log "src_root=#{input.src_root}"
      log "build_root=#{input.build_root}"
      log "temp_dir=#{@jaba_temp_dir}"
      log "config_file=#{@config_file}"    
    end

    ##
    #
    def src_root_valid?
      input.src_root && load_path_valid?(input.src_root)
    end

    ##
    #
    def set_global_attrs_from_cmdline
      input.global_attrs.each do |name, values|
        attr = @globals_node.get_attr(name.to_sym, fail_if_not_found: false)
        if attr.nil?
          @input_manager.usage_error("'#{name}' attribute not defined in :globals type")
        end

        type = attr.attr_def.jaba_attr_type
        case attr.attr_def.variant
        when :single
          if values.size > 1
            @input_manager.usage_error("'#{name}' attribute only expects one value but #{values} provided")
          end
          value = type.from_string(values[0])
          if attr.type_id == :file || attr.type_id == :dir
            value.to_absolute!(base: @services.invoking_dir, clean: true) # TODO: need to do this for array/hash elems too
          end
          attr.set(value)
        when :array
          if values.empty?
            @input_manager.usage_error("'#{name}' array attribute requires one or more values")
          end
          attr.set(values.map{|v| type.from_string(v)})
        when :hash
          if values.empty? || values.size % 2 != 0
            @input_manager.usage_error("'#{name}' hash attribute requires one or more pairs of values")
          end
          key_type = attr.attr_def.jaba_attr_key_type
          values.each_slice(2) do |kv|
            key = key_type.from_string(kv[0])
            value = type.from_string(kv[1])
            attr.set(key, value)
          end
        end
      end
    end

    ##
    #
    def process_config_file
      # Create config.jaba if it does not exist, which will write in any config options defined on the command line
      #
      # TODO: automatically patch in new attrs
      if !File.exist?(@config_file)
        file = @file_manager.new_file(@config_file, track: false, eol: :native)
        w = file.writer

        @globals_node.visit_attr(top_level: true) do |attr, value|
          attr_def = attr.attr_def

          # TODO: include ref manual type docs, eg type, definition location etc
          comment = String.new("#{attr_def.title}. #{attr_def.notes.join("\n")}")
          comment.wrap!(130, prefix: '# ')

          w << "##"
          w << comment
          w << "#"
          if attr.hash?
            value.each do |k, v|
              w << "#{attr_def.defn_id} #{k.inspect}, #{v.inspect}"
            end
          else
            w << "#{attr_def.defn_id} #{value.inspect}"
          end
          w << ''
        end
        w.chomp!

        file.write
      end
    end

    ##
    #
    def create_core_objects
      constants = JABA.constants(false) # Don't iterate directly as constants get created inside loop
      constants.each do |c|
        case c
        when /^JabaAttributeType./
          make_attr_type(JABA.const_get(c))
        when /^JabaAttrDefFlag./
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
        JABA.error("Attribute type multiply defined [id=#{at.id}, class=#{klass}]")
      end
      at.instance_variable_set(:@services, self)
      at.post_create
      @jaba_attr_types << at
      @jaba_attr_type_lookup[at.id] = at
      at
    end

    ##
    #
    def make_attr_flag(klass)
      af = klass.new
      if @jaba_attr_flag_lookup.has_key?(af.id)
        JABA.error("Attribute flag multiply defined [id=#{af.id}, class=#{klass}]")
      end
      af.instance_variable_set(:@services, self)
      af.post_create
      @jaba_attr_flags << af
      @jaba_attr_flag_lookup[af.id] = af
      af
    end

    ##
    #
    def make_definition(id, block, src_loc)
      d = OpenStruct.new
      d.id = id
      d.block = block
      d.src_loc = src_loc
      d.open_defs = []
      d.jaba_type_id = nil
      d
    end

    ##
    #
    def make_top_level_type(handle, dfn)
      log "Instancing top level JabaType [handle=#{handle}]"

      if @jaba_type_lookup.key?(handle)
        JABA.error("'#{handle}' jaba type multiply defined")
      end

      generator_id = dfn.id.to_s.capitalize_first
      generator = @generator_lookup[generator_id]
      if generator.nil?
        generator = DefaultGenerator.new(self)
      end

      tlt = TopLevelJabaType.new(self, dfn.id, dfn.src_loc, dfn.block, handle, generator)
      generator.set_top_level_type(tlt)

      @top_level_jaba_types  << tlt
      @jaba_type_lookup[handle] = tlt

      tlt
    end

    ##
    #
    def get_top_level_jaba_type(id, fail_if_not_found: true, errobj: nil)
      jt = @jaba_type_lookup[id]
      if !jt && fail_if_not_found
        JABA.error("'#{id}' type not defined", errobj: errobj)
      end
      jt
    end

    ##
    #
    def validate_id(id)
      if !(id.symbol? || id.string?) || id !~ /^[a-zA-Z0-9_\-.]+$/
        JABA.error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
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
        JABA.error("'#{id}' attribute type is undefined. Valid types: [#{@jaba_attr_types.map{|at| at.id.inspect}.join(', ')}]")
      end
      t
    end

    ##
    #
    def get_attribute_flag(id)
      f = @jaba_attr_flag_lookup[id]
      if !f
        JABA.error("'#{id.inspect_unquoted}' is an invalid flag. Valid flags: [#{@jaba_attr_flags.map{|at| at.id.inspect}.join(', ')}]")
      end
      f
    end

    ##
    #
    def define_type(id, &block)
      JABA.error("id is required") if id.nil?
      log "  Defining type [id=#{id}]"
      validate_id(id)
      existing = @jaba_type_defs.find{|d| d.id == id}
      if existing
        JABA.error("Type '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc.describe}.")
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
      JABA.error("id is required") if id.nil?
      JABA.error("A block is required") if !block_given?

      log "  Defining shared definition [id=#{id}]"
      validate_id(id)

      existing = get_shared_definition(id, fail_if_not_found: false)
      if existing
        JABA.error("Shared definition '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc.describe}.")
      end

      @shared_def_lookup[id] = make_definition(id, block, caller_locations(2, 1)[0])
      nil
    end

    ##
    #
    def get_shared_definition(id, fail_if_not_found: true)
      d = @shared_def_lookup[id]
      if !d && fail_if_not_found
        JABA.error("Shared definition '#{id}' not found")
      end
      d
    end

    ##
    #
    def define_instance(type_id, id, &block)
      JABA.error("type_id is required") if type_id.nil?
      JABA.error("id is required") if id.nil?

      validate_id(id)

      log "  Defining instance [id=#{id}, type=#{type_id}]"

      existing = get_instance_definition(type_id, id, fail_if_not_found: false)
      if existing
        JABA.error("Type instance '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc.describe}.")
      end
      
      d = make_definition(id, block, caller_locations(2, 1)[0])
      d.jaba_type_id = type_id

      @instance_def_lookup.push_value(type_id, d)
      @instance_defs << d
      nil
    end
    
    ##
    #
    def get_instance_definition(type_id, id, fail_if_not_found: true, errobj: nil)
      defs = @instance_def_lookup[type_id]
      d = defs&.find {|dd| dd.id == id}
      if !d && fail_if_not_found
        JABA.error("'#{id}' instance not defined", errobj: errobj)
      end
      d
    end

    ##
    #
    def get_instance_ids(type_id)
      defs = @instance_def_lookup[type_id]
      if !defs
        JABA.error("No '#{type_id}' type defined")
      end
      defs.map(&:id)
    end

    ##
    #
    def define_defaults(id, &block)
      JABA.error("id is required") if id.nil?
      log "  Defining defaults [id=#{id}]"
      existing = @default_defs.find {|d| d.id == id}
      if existing
        JABA.error("Defaults block '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc.describe}.")
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
      JABA.error("id is required") if id.nil?
      log "  Defining translator [id=#{id}]"
      existing = get_translator_definition(id, fail_if_not_found: false)
      if existing
        JABA.error("Translator block '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc.describe}.")
      end
      @translator_defs << make_definition(id, block, caller_locations(2, 1)[0])
      nil
    end

    ##
    #
    def get_translator_definition(id, fail_if_not_found: true)
      td = @translator_defs.find {|d| d.id == id}
      if !td && fail_if_not_found
        JABA.error("'#{id.inspect_unquoted}' translator not found")
      end
      td
    end

    ##
    #
    def get_translator(id, fail_if_not_found: true)
      t = @translators[id]
      if !t && fail_if_not_found
        JABA.error("'#{id.inspect_unquoted}' translator not found")
      end
      t
    end

    ##
    #
    def open(what, id, type=nil, &block)
      JABA.error("id is required") if id.nil?
      JABA.error("A block is required") if !block_given?
      src_loc = caller_locations(2, 1)[0]

      case what
      when :type
        log "  Opening type [id=#{id}]"
        @open_type_defs << make_definition(id, block, src_loc)
      when :instance
        log "  Opening instance [id=#{id} type=#{type}]"
        JABA.error("type is required") if type.nil?
        d = make_definition(id, block, src_loc)
        d.jaba_type_id = type
        @open_instance_defs << d
      when :translator
        log "  Opening translator [id=#{id}]"
        @open_translator_defs << make_definition(id, block, src_loc)
      when :shared
        log "  Opening shared definition [id=#{id}]"
        @open_shared_defs << make_definition(id, block, src_loc)
      end
      nil
    end

    ##
    #
    def get_generator(top_level_type_id)
      g = @generators.find {|g| g.type_id == top_level_type_id}
      JABA.error("'#{top_level_type_id.inspect_unquoted}' generator not found") if !g
      g
    end

    ##
    #
    def get_null_node(type_id)
      nn = @null_nodes[type_id]
      if !nn
        jt = get_top_level_jaba_type(type_id)
        nn = JabaNode.new(self, jt.defn_id, jt.src_loc, jt, "Null#{jt.defn_id}", nil, 0)
        @null_nodes[type_id] = nn
      end
      nn
    end

    ##
    #
    def dump_jaba_state
      root = {}
      root[:jdl_files] = @jdl_files

      @generators.each do |g|
        g.root_nodes.each do |rn|
          obj = {}
          root["#{g.type_id}|#{rn.handle}"] = obj
          write_node_json(g, root, rn, obj)
        end
      end
      json = JSON.pretty_generate(root)
      file = @file_manager.new_file('.jaba/jaba.state.json'.to_absolute(base: input.build_root, clean: true), eol: :native, track: false)
      w = file.writer
      w.write_raw(json)
      file.write
    end

    ##
    #
    def write_node_json(generator, root, node, obj)
      node.visit_attr(top_level: true) do |attr, val|
        obj[attr.defn_id] = val
      end
      if !node.children.empty?
        node.children.each do |child|
          child_obj = {}
          root["#{generator.type_id}|#{child.handle}"] = child_obj
          write_node_json(generator, root, child, child_obj)
        end
      end
    end

    ##
    #
    def build_jaba_output
      log 'Building output...'
      
      out_file = globals.jaba_output_file
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

      if globals.dump_output
        json = JSON.pretty_generate(@output)
        file = @file_manager.new_file(out_file, eol: :native)
        w = file.writer
        w.write_raw(json)
        file.write
      end

      # Include all generated files for the purpose of reporting back to the user.
      #
      @file_manager.include_untracked

      # Now make files that will be reported back to the user relative to build_root
      #
      @generated = @file_manager.generated.map{|f| f.relative_path_from(input.build_root)}
      @added = @file_manager.added.map{|f| f.relative_path_from(input.build_root)}.sort_no_case!
      @modified = @file_manager.modified.map{|f| f.relative_path_from(input.build_root)}.sort_no_case!

      # These are not included in the output file but are returned to outer context
      #
      @output[:added] = @added
      @output[:modified] = @modified
    end

    ##
    #
    def include_jdl_file(filename)
      if !filename.absolute_path?
        src_loc = caller_locations(2, 1)[0]
        filename = "#{src_loc.absolute_path.dirname}/#{filename}"
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
    rescue JabaError
      raise # Prevent fallthrough to next case
    rescue StandardError => e # Catches errors like invalid constants
      JABA.error(e.message, callstack: e.backtrace, include_api: true)
    rescue ScriptError => e # Catches syntax errors. In this case there is no backtrace.
      JABA.error(e.message, syntax: true)
    end

    ##
    #
    def load_module_ruby_files
      # Only loaded once in a given process even if jaba invoked multiple times. Helps with effiency of tests.
      #
      return if @@module_ruby_files_loaded
      @@module_ruby_files_loaded = true
      plugin_files = []

      Dir.glob("#{JABA.modules_dir}/**/*").each do |f|
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
    def load_jaba_files
      if input.barebones?
        process_jaba_file("#{JABA.modules_dir}/core/globals.jaba") # globals always needs loading
      else
        @@module_jaba_files.each do |f|
          process_jaba_file(f)
        end
      end

      # Process config file
      #
      if File.exist?(@config_file)
        process_jaba_file(@config_file)
      end

      if input.src_root
        process_load_path(input.src_root, fail_if_empty: true)
      end

      # Definitions can also be provided in a block form
      #
      Array(input.definitions).each do |block|
        block_file = block.source_location[0].cleanpath
        @jdl_files << block_file
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
    def load_path_valid?(path)
      !@file_manager.glob("#{path}/*.jaba").empty?
    end

    ##
    #
    def process_load_path(p, fail_if_empty: false)
      if !p.absolute_path?
        JABA.error("'#{p}' must be an absolute path")
      end

      if !File.exist?(p)
        JABA.error("'#{p}' does not exist", want_backtrace: false)
      end

      if File.directory?(p)
        files = @file_manager.glob("#{p}/*.jaba")
        if files.empty?
          msg = "No .jaba files found in '#{p}'"
          if fail_if_empty
            JABA.error(msg, want_backtrace: false)
          else
            jaba_warn(msg)
          end
        else
          files.each do |f|
            process_jaba_file(f)
          end
        end
      else
        process_jaba_file(p)
      end
    end

    ##
    #
    def process_jaba_file(f)
      if !f.absolute_path?
        JABA.error("'#{f}' must be an absolute path")
      end
      f = f.cleanpath

      if @jdl_file_lookup.has_key?(f)
        JABA.error("'#{f}' multiply included")
      end
      @jdl_file_lookup[f] = nil
      @jdl_files << f

      # Special handling for config.jaba
      #
      if f.basename == 'config.jaba'
        if !@config_loaded
          @config_loaded = true
          content = @file_manager.read(f, freeze: false)
          content.prepend("open_instance :globals, type: :globals do\n")
          content << "end"
          execute_jdl(file: f, str: content)
        end
      else
        execute_jdl(file: f)
      end
    end

    ##
    #
    def log(msg, severity = :INFO, section: false)
      return if !@log_msgs
      if section
        max_width = 130
        n = ((max_width - msg.size)/2).round
        if n > 2
          msg = "#{'=' * n} #{msg} #{'=' * n}"
        end
      end
      @log_msgs << "#{severity} #{msg}"
    end

    ##
    #
    def term_log
      return if !@log_msgs
      log_fn = "#{@jaba_temp_dir}/jaba.log"
      if File.exist?(log_fn)
        File.delete(log_fn)
      else
        FileUtils.makedirs(log_fn.dirname)
      end
      IO.write(log_fn, @log_msgs.join("\n"))
    end

    ##
    #
    def jaba_warn(msg, errobj: nil)
      callstack = Array(errobj&.src_loc || caller)
      jdl_bt = get_jdl_backtrace(callstack)
      if jdl_bt.empty?
        msg = "Warning: #{msg}"
      else
        msg = jdl_error_info(msg, jdl_bt, err_type: :warning).message
      end
      log(msg, :WARN)
      @warnings << msg
      nil
    end

    ##
    #
    def get_jdl_backtrace(callstack, include_api: false)
      # Clean up callstack which could be in 'caller' or 'caller_locations' form.
      #
      callstack = callstack.map do |l|
        if l.is_a?(::Thread::Backtrace::Location)
          "#{l.absolute_path}:#{l.lineno}"
        else
          l
        end
      end

      # Disregard everything after the main entry point, if it is present in callstack. Prevents error handling from
      # getting confused when definitions are supplied in block form where normal source code and jdl source code
      # exist in the same file.
      #
      jaba_run_idx = callstack.index{|l| l =~ /jaba\/lib\/jaba\.rb.*in `run'/}
      if jaba_run_idx
        callstack.slice!(jaba_run_idx..-1)
      end

      candidates = include_api ? @jdl_files + $LOADED_FEATURES.select{|f| f =~ /jaba\/lib\/jaba\/jdl/} : @jdl_files

      # Extract any lines in the callstack that contain references to definition source files.
      #
      jdl_bt = callstack.select {|c| candidates.any? {|sf| c.include?(sf)}}

      # remove the unwanted ':in ...' suffix from user level definition errors
      #
      jdl_bt.map!{|l| l.clean_backtrace}
      
      # Can contain unhelpful duplicates due to loops, make unique.
      #
      jdl_bt.uniq!

      jdl_bt
    end

    ##
    #
    def jdl_error_info(msg, backtrace, err_type: :error)
      if err_type == :syntax
        # With ruby ScriptErrors there is no useful callstack. The error location is in the msg itself.
        #
        err_line = msg

        # Delete ruby's way of reporting syntax errors in favour of our own
        #
        msg = msg.sub(/^.* syntax error, /, '')
      else
        err_line = backtrace[0]
      end
      
      # Extract file and line information from the error line.
      #
      if err_line !~ /^(.+):(\d+)/
        raise "Could not extract file and line number from '#{err_line}'"
      end

      file = Regexp.last_match(1)
      line = Regexp.last_match(2).to_i

      m = String.new
      
      m << case err_type
      when :error
        'Error'
      when :warning
        'Warning'
      when :syntax
        'Syntax error'
      else
        raise "Invalid error type '#{err_type}'"
      end
      
      m << ' at'
      m << " #{file.basename}:#{line}"
      m << ": #{msg}"
      if m =~ /[a-zA-Z0-9']$/
        m.ensure_end_with!('.')
      end

      # Format full message, which includes backtrace. First backtrace entry is the error line
      # which has already been reported in the main error line, so only show the backtrace if it
      # contains more than one item.
      #
      fm = String.new(m)
      if backtrace.size > 1
        fm << "\nTrace:\n"
        backtrace.each do |bt|
          fm << "  " << bt << "\n"
        end
      end
      
      e = OpenStruct.new
      e.message = m
      e.full_message = fm
      e.file = file
      e.line = line
      e
    end

    ##
    #
    def profile(enabled)
      if !enabled
        yield
        return
      end

      begin
        require 'ruby-prof'
      rescue LoadError
        JABA.error( "ruby-prof gem is required to run with --profile. Could not be loaded.", want_backtrace: false)
      end

      puts 'Invoking ruby-prof...'
      RubyProf.start
      yield
      result = RubyProf.stop
      file = "#{@jaba_temp_dir}/jaba.profile"
      str = String.new
      puts "Write profiling results to #{file}..."
      [RubyProf::FlatPrinter, RubyProf::GraphPrinter].each do |p|
        printer = p.new(result)
        printer.print(str)
      end
      IO.write(file, str)
    end

  end

end
