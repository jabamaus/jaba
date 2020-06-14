# frozen_string_literal: true

# The only ruby library files that Jaba core depends on
require 'digest/sha1'
require 'json'
require 'tsort'

require_relative 'core_ext'
require_relative 'hook'
require_relative 'utils'
require_relative 'file_manager'
require_relative 'property'
require_relative 'jdl_object'
require_relative 'jaba_attribute_type'
require_relative 'jaba_attribute_flag'
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
require_relative '../extend/vsproj'
require_relative '../extend/vcxproj'
require_relative '../extend/xcodeproj'

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
  def self.cwd
    @@cwd ||= Dir.getwd
  end
  
  ##
  #
  class Services

    attr_reader :input
    attr_reader :file_manager
    attr_reader :globals_node

    ##
    #
    def initialize
      @input = Input.new
      @input.instance_variable_set(:@definitions, [])
      @input.instance_variable_set(:@jaba_input_file, 'jaba.input.json')
      @input.instance_variable_set(:@dump_input, false)
      @input.instance_variable_set(:@jaba_output_file, 'jaba.output.json'.to_absolute)
      @input.instance_variable_set(:@dump_output, true)
      @input.instance_variable_set(:@dry_run, false)
      @input.instance_variable_set(:@enable_logging, false)
      @input.instance_variable_set(:@barebones, false)
      @input.instance_variable_set(:@jdl_paths, [JABA.cwd])

      @output = {}
      
      @log_file = nil
      
      @jdl_backtrace_files = [] # Files to include in jdl level error backtraces. Includes jdl files and api files.
      @warnings = []
      @warn_object = nil
      
      @jdl_files = []
      
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
      @jaba_attr_flags = []
      @top_level_jaba_types = []
      @jaba_type_lookup = {}
      @translators = {}

      @generators = []

      @globals_node = nil
      @null_nodes = {}
      
      @in_attr_default_block = false

      @top_level_api = JDL_TopLevel.new(self)
      @default_attr_type = JabaAttributeType.new(self, JabaDefinition.new(nil, nil, caller_locations(0, 1)[0])).freeze
      @file_manager = FileManager.new(self)
    end

    ##
    #
    def run
      init_log if input.enable_logging?
      log 'Starting Jaba', section: true

      duration = JABA.milli_timer do
        do_run
      end

      summary = String.new "Generated #{@generated.size} files, #{@added.size} added, #{@modified.size} modified in #{duration}"
      summary << " [dry run]" if input.dry_run?

      log summary

      @output[:summary] = summary
      @output[:warnings] = @warnings.uniq # Strip duplicate warnings

      log "Done! (#{duration})"

      @output
    ensure
      term_log
    end

    ##
    #
    def do_run
      load_modules

      #@jdl_backtrace_files.concat($LOADED_FEATURES.select{|f| f =~ /jaba\/lib\/jaba\/jdl_api/})
      @jdl_backtrace_files.concat(@jdl_files)
      
      Array(input.definitions).each do |block|
        @jdl_backtrace_files << block.source_location[0]
      end

      @jdl_files.each do |f|
        execute_jdl(f)
      end

      # Definitions can also be provided in a block associated with the main 'jaba' entry point.
      # Execute if it was supplied.
      #
      Array(input.definitions).each do |block|
        execute_jdl(&block)
      end
      
      # Create attribute types
      #
      @attr_type_defs.each do |d|
        @jaba_attr_types << JabaAttributeType.new(self, d)
      end
      
      # Create attribute flags, which are used in attribute definitions
      #
      @attr_flag_defs.each do |d|
        @jaba_attr_flags << JabaAttributeFlag.new(self, d)
      end

      # Create JabaTypes and any associated Generators
      #
      @jaba_type_defs.each do |d|
        make_top_level_type(d.id, d)
      end

      # Open top level JabaTypes so more attributes can be added
      #
      @open_type_defs.each do |d|
        get_top_level_jaba_type(d.id, callstack: d.source_location).eval_jdl(&d.block)
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
        jaba_error("'#{err_type}' contains a cyclic dependency", callstack: err_type.definition.source_location)
      end

      log 'Initialisation of JabaTypes complete'

      # Now that the JabaTypes are dependency sorted build generator list from them, so they are in dependency order too
      #
      @generators = @top_level_jaba_types.map(&:generator)

      # Process instance definitions and assign them to a generator
      #
      @instance_defs.each do |d|
        jt = get_top_level_jaba_type(d.jaba_type_id, callstack: d.source_location)
        jt.generator.register_instance_definition(d)
      end

      # Register instance open defs
      #
      @open_instance_defs.each do |d|
        inst_def = get_instance_definition(d.instance_variable_get(:@jaba_type_id), d.id, callstack: d.source_location)
        inst_def.add_open_def(d)
      end

      # Create translators
      #
      @translator_defs.each do |d|
        t = Translator.new(self, d)
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

      # Process generators
      #
      @generators.each do |g|
        log "Processing #{g.type_id} generator", section: true
        g.process
      end
     
      # Output definition input data as a json file, before generation. This is raw data as generated from the definitions.
      # Can be used for debugging and testing.
      #
      if input.dump_input?
        dump_jaba_input
      end

      log 'Performing file generation...'

      # Write final files
      #
      @generators.each(&:perform_generation)

      log 'Building output...'
      build_jaba_output
    end
    
    ##
    #
    def make_top_level_type(handle, definition)
      log "Instancing top level JabaType [handle=#{handle}]"

      if @jaba_type_lookup.key?(handle)
        jaba_error("'#{handle}' jaba type multiply defined")
      end

      jt = TopLevelJabaType.new(self, definition, handle)

      if definition.block
        jt.eval_jdl(&definition.block)
      end

      @top_level_jaba_types  << jt
      @jaba_type_lookup[handle] = jt
      jt
    end

    ##
    #
    def get_top_level_jaba_type(id, fail_if_not_found: true, callstack: nil)
      jt = @jaba_type_lookup[id]
      if !jt && fail_if_not_found
        jaba_error("'#{id}' type not defined", callstack: callstack)
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
    def define_attr_type(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Defining attr type [id=#{id}]"
      validate_id(id)
      existing = @attr_type_defs.find{|d| d.id == id}
      if existing
        jaba_error("Attribute type '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      @attr_type_defs << JabaDefinition.new(id, block, caller_locations(2, 1)[0])
      nil
    end

   ##
    #
    def get_attribute_type(id)
      if id.nil?
        return @default_attr_type
      end
      t = @jaba_attr_types.find {|at| at.defn_id == id}
      if !t
        jaba_error("'#{id}' attribute type is undefined. Valid types: #{@jaba_attr_types.map(&:defn_id)}")
      end
      t
    end

    ##
    #
    def define_attr_flag(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Defining attr flag [id=#{id}]"
      validate_id(id)
      existing = @attr_flag_defs.find{|d| d.id == id}
      if existing
        jaba_error("Attribute flag '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      @attr_flag_defs << JabaDefinition.new(id, block, caller_locations(2, 1)[0])
      nil
    end

    ##
    #
    def get_attribute_flag(id)
      f = @jaba_attr_flags.find {|af| af.defn_id == id}
      if !f
        jaba_error("'#{id.inspect_unquoted}' is an invalid flag. Valid flags: #{@jaba_attr_flags.map(&:defn_id)}")
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
        jaba_error("Type '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      d = JabaDefinition.new(id, block, caller_locations(2, 1)[0])
      if id == :globals
        @jaba_type_defs.prepend(d)
      else
        @jaba_type_defs << d
      end
      nil
    end
    
    ##
    #
    def define_shared(id, &block)
      jaba_error("id is required") if id.nil?
      jaba_error("a block is required") if !block_given?

      log "  Defining shared definition [id=#{id}]"
      validate_id(id)

      existing = get_shared_definition(id, fail_if_not_found: false)
      if existing
        jaba_error("Shared definition '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end

      @shared_def_lookup[id] = JabaDefinition.new(id, block, caller_locations(2, 1)[0])
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
        jaba_error("Type instance '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      
      d = JabaInstanceDefinition.new(id, type_id, block, caller_locations(2, 1)[0])
      @instance_def_lookup.push_value(type_id, d)
      @instance_defs << d
      nil
    end
    
    ##
    #
    def get_instance_definition(type_id, id, fail_if_not_found: true, callstack: nil)
      defs = @instance_def_lookup[type_id]
      d = defs&.find {|dd| dd.id == id}
      if !d && fail_if_not_found
        jaba_error("'#{id}' instance not defined", callstack: callstack)
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
        jaba_error("Defaults block '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      @default_defs << JabaDefinition.new(id, block, caller_locations(2, 1)[0])
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
        jaba_error("Translator block '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      @translator_defs << JabaDefinition.new(id, block, caller_locations(2, 1)[0])
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
      jaba_error("a block is required") if !block_given?
      call_loc = caller_locations(2, 1)[0]

      case what
      when :type
        log "  Opening type [id=#{id}]"
        @open_type_defs << JabaDefinition.new(id, block, call_loc)
      when :instance
        log "  Opening instance [id=#{id} type=#{type}]"
        jaba_error("type is required") if type.nil?
        d = JabaDefinition.new(id, block, call_loc)
        d.instance_variable_set(:@jaba_type_id, type)
        @open_instance_defs << d
      when :translator
        log "  Opening translator [id=#{id}]"
        @open_translator_defs << JabaDefinition.new(id, block, call_loc)
      when :shared
        log "  Opening shared definition [id=#{id}]"
        @open_shared_defs << JabaDefinition.new(id, block, call_loc)
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
        nn = JabaNode.new(self, jt.definition, jt, "Null#{jt.defn_id}", nil, 0)
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
      file = @file_manager.new_file(input.jaba_input_file, eol: :unix, track: false)
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
      children = {}
      obj[:children] = children
      node.children.each do |child|
        child_obj = {}
        children[child.handle] = child_obj
        write_node_json(child, child_obj)
      end
    end

    ##
    #
    def build_jaba_output
      out_file = input.jaba_output_file
      out_dir = out_file.dirname

      @generated = @file_manager.generated
      
      if input.dump_output?
        @generated = @generated.map{|f| f.relative_path_from(out_dir)}
      end

      @output[:version] = '1.0'
      @output[:generated] = @generated

      if input.dump_output?
        @generators.each do |g|
          next if g.is_a?(DefaultGenerator)
          g_root = {}
          g.build_jaba_output(g_root, out_dir)
          if !g_root.empty?
            @output[g.type_id] = g_root
          end
        end

        json = JSON.pretty_generate(@output)
        file = @file_manager.new_file(out_file, eol: :unix)
        w = file.writer
        w.write_raw(json)
        file.write
      end
      
      @added = @file_manager.added
      @modified = @file_manager.modified
      
      if input.dump_output?
        @added = @added.map{|f| f.relative_path_from(out_dir)}
        @modified = @modified.map{|f| f.relative_path_from(out_dir)}
      end

      # These are not included in the output file but are returned to outer context
      #
      @output[:added] = @added
      @output[:modified] = @modified
    end

    ##
    # This will cause a series of calls to eg define_attr_type, define_type, define_instance (see further
    # down in this file). These calls will come from user definitions via the api files.
    #
    def execute_jdl(file = nil, &block)
      if file
        log "Executing #{file}"
        @top_level_api.instance_eval(file_manager.read_file(file), file)
      end
      if block_given?
        @top_level_api.instance_eval(&block)
      end
    rescue JDLError
      raise # Prevent fallthrough to next case
    rescue StandardError => e # Catches errors like invalid constants
      jaba_error(e.message, callstack: e.backtrace)
    rescue ScriptError => e # Catches syntax errors. In this case there is no backtrace.
      jaba_error(e.message, syntax: true)
    end

    ##
    #
    def load_modules
      modules_dir = "#{__dir__}/../modules".cleanpath
      require_relative '../modules/text/text_generator.rb'
      require_relative '../modules/cpp/cpp_generator.rb'
      require_relative '../modules/workspace/workspace_generator.rb'

      # Load core type definitions
      #
      if input.barebones?
        [:attribute_flags, :attribute_types].each do |d|
          @jdl_files << "#{modules_dir}/core/#{d}.jdl.rb"
        end
      else
        @jdl_files.concat(@file_manager.glob("#{modules_dir}/**/*.jdl.rb"))
      end
      
      Array(input.jdl_paths).each do |p|
        p = p.to_absolute(clean: true)

        if !File.exist?(p)
          jaba_error("#{p} does not exist")
        end

        if File.directory?(p)
          files = @file_manager.glob("#{p}/**/*.jdl.rb")
          if files.empty?
            jaba_warning("No definition files found in #{p}")
          else
            @jdl_files.concat(files)
          end
        else
          @jdl_files << p
        end
      end
      @jdl_files.uniq!
    end

    ##
    #
    def init_log
      log_fn = 'jaba.log'.to_absolute
      puts "Logging to #{log_fn}..."
      
      File.delete(log_fn) if File.exist?(log_fn)
      @log_file = File.open(log_fn, 'a')
    end

    ##
    #
    def log(msg, severity = :INFO, section: false)
      return if !@log_file
      line = msg
      if section
        n = ((96 - msg.size)/2).round
        line = "#{'=' * n} #{msg} #{'=' * n}"
      end
      @log_file.puts("#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{severity} #{line}")
    end

    ##
    #
    def term_log
      return if !@log_file
      @log_file.flush
      @log_file.close
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
      log msg, :WARN
      if @warn_object
        options[:callstack] = @warn_object.is_a?(JDL_Object) ? @warn_object.definition.source_location : @warn_object
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
    def make_jaba_error(msg, syntax: false, callstack: nil, warn: false, user_error: false)
      msg = msg.capitalize_first if msg.split.first !~ /_/
      
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
        backtrace = Array(callstack || caller).map do |l|
          if l.is_a?(::Thread::Backtrace::Location)
            "#{l.absolute_path}:#{l.lineno}"
          else
            l
          end
        end

        # Extract any lines in the callstack that contain references to definition source files.
        #
        lines = backtrace.select {|c| @jdl_backtrace_files.any? {|sf| c.include?(sf)}}

        # remove the unwanted ':in ...' suffix from user level definition errors
        #
        lines.map!{|l| l.sub(/:in .*/, '')}
        
        # If no references to jdl files assume the error came from internal library code and raise a RuntimeError,
        # unless its specifically flagged as a user error, which can happen when validating jaba input, before any
        # definitions are executed.
        #
        if lines.empty?
          e = if user_error
                e = JDLError.new(msg)
                e.instance_variable_set(:@raw_message, msg)
                e.instance_variable_set(:@file, nil)
                e.instance_variable_set(:@line, nil)
                e
              else
                RuntimeError.new(msg)
              end
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
      
      e = JDLError.new(m)
      e.instance_variable_set(:@raw_message, msg)
      e.instance_variable_set(:@file, file)
      e.instance_variable_set(:@line, line)
      e.set_backtrace(lines)
      e
    end

  end

end
