# The only ruby library files that Jaba core depends on. When run in test mode these will be taken from the ruby
# distro and when jaba is run standalone they are taken from the ones in $(jaba_install)/lib/ruby_stdlib.
#
require 'digest/sha1'
require 'json'
require 'fileutils'
require 'tsort'

require_relative 'core_ext'
require_relative 'utils'
require_relative 'jdl'
require_relative 'file_manager'
require_relative 'load_manager'
require_relative 'node_manager'
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
require_relative '../extend/plugin'
require_relative '../extend/src'
require_relative '../extend/vsproj'

module JABA
  class Services
    include TopLevelAPI

    attr_reader :invoking_dir
    attr_reader :input
    attr_reader :output
    attr_reader :file_manager
    attr_reader :globals
    attr_reader :globals_node
    attr_reader :jaba_attr_types
    attr_reader :jaba_temp_dir

    def test_mode? = @test_mode
    
    def initialize(test_mode: false)
      @test_mode = test_mode
      @invoking_dir = Dir.getwd.freeze
      @jaba_temp_dir = nil

      @input = Input.new
      @input.instance_variable_set(:@build_root, nil)
      @input.instance_variable_set(:@src_root, nil)
      @input.instance_variable_set(:@definitions, [])
      @input.instance_variable_set(:@global_attrs, {})
      @input.instance_variable_set(:@dump_output, true)
      @output = {}
      
      @log_msgs = test_mode? ? nil : [] # Disable logging when running tests
      @warnings = []
      
      @definition_registry = {}
      @open_definitions_registry = {}

      @node_lookup = {}
      @node_manager_lookup = {}
      @plugin_lookup = {}

      @jaba_attr_types = []
      @jaba_attr_type_lookup = {}
      @jaba_attr_flags = []
      @jaba_attr_flag_lookup = {}
      @jaba_types = []
      @jaba_type_lookup = {}
      @translators = {}

      @globals = nil
      @globals_node = nil

      @null_attr_type = JabaAttributeType.new(:null, 'Null attribute type')
      
      @in_attr_default_block = false

      @file_manager = FileManager.new(self)
      @load_manager = LoadManager.new(self, @file_manager)

      @top_level_api = JDL_TopLevel.new(self)

      register_toplevel_item :type, :instance, :shared, :defaults, :translator
    end

    # The output of inspecting Services is massive and chokes debugger
    #
    def inspect = 'Services'

    def execute
      begin
        yield
      rescue => e
        log e.full_message(highlight: false), :ERROR

        case e
        when JabaError
          cs = e.instance_variable_get(:@callstack)
           err_type = e.instance_variable_get(:@syntax) ? :syntax : :error
          want_backtrace = e.instance_variable_get(:@want_backtrace)
          
          bt = if err_type == :syntax
            [] # Syntax errors (ruby ScriptErrors) don't have backtraces
          else
            jdl_bt = get_jdl_backtrace(cs)
            if jdl_bt.empty?
              @output[:error] = want_backtrace ? e.full_message(highlight: false) : e.message
              raise
            end
            jdl_bt
          end

          info = make_error_info(e.message, bt, err_type: err_type)
          @output[:error] = want_backtrace ? info.full_message : info.message

          e = JabaError.new(info.message)
          e.instance_variable_set(:@file, info.file)
          e.instance_variable_set(:@line, info.line)
          e.set_backtrace(bt)
          raise e
        else
          @output[:error] = e.full_message(highlight: false)
          raise
        end
      ensure
        term_log
      end
    end

    def run
      log "Starting Jaba at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}", section: true
      
      duration = JABA.milli_timer do
        profile(input.profile?) do
          do_run
          build_output
        end
      end

      summary = "Generated #{@generated.size} files, #{@added.size} added, #{@modified.size} modified, #{@unchanged.size} unchanged in #{duration}"
      summary << " [dry run]" if input.dry_run?
      summary << "\n"

      @added.each do |f|
        summary << "  #{f} [A]\n"
      end
      @modified.each do |f|
        summary << "  #{f} [M]\n"
      end
      if input.verbose?
        @unchanged.each do |f|
          summary << "  #{f} [UNCHANGED]\n"
        end
      end

      log summary
      log "Done! (#{duration})"

      @output[:summary] = summary
      @output[:warnings] = @warnings.uniq # Strip duplicate warnings
      @output[:services] = self # internal access for unit testing
      @output
    end

    def do_run
      @load_manager.load_modules
      init_root_paths
      @load_manager.load_jaba_files(input)
      create_core_objects

      execute_jdl do
        open_type :globals do
          plugin :globals do
            def process_definition(definition)
              globals_node = services.make_node(definition, flags: NodeFlags::NO_POST_CREATE)
              
              main_services = services.instance_variable_get(:@services)
              main_services.instance_variable_set(:@globals_node, globals_node)
              main_services.instance_variable_set(:@globals, globals_node.attrs)
        
              main_services.set_global_attrs_from_cmdline
        
              globals_node.post_create
              globals_node
            end
          end
        end
      end
      # Associate open definitions with definition they are opening
      # TODO: validation
      @definition_registry.each do |what, def_reg|
        open_def_reg = @open_definitions_registry[what]
        def_reg.defs.each do |d|
          d.open_defs = open_def_reg.lookup[d.open_defs_lookup_id]
        end
      end

      # Create translators
      #
      iterate_defs(:translator) do |d|
        t = Translator.new(self, d.id, d.src_loc, d.block, d.open_defs)
        @translators[d.id] = t
      end
      
      #@open_type_defs_lookup.each do |id, open_defs|
      #  if !get_definition(:type, id, fail_if_not_found: false)
      #    JABA.error("Cannot open undefined type '#{id.inspect_unquoted}'", errobj: open_defs[0])
      #  end
      #end

      iterate_defs(:instance) do |d|
        if !get_definition(:type, d.jaba_type_id, fail_if_not_found: false)
          JABA.error("Cannot instance undefined type '#{d.jaba_type_id.inspect_unquoted}'", errobj: d)
        end
      end

      #@open_instance_defs.each do |id|
      #  if !get_instance_definition(id)
      #  if !get_definition(:type, id, fail_if_not_found: false)
      #    JABA.error("Cannot open instance of undefined type '#{id.inspect_unquoted}'", errobj: inst_defs[0])
      #  end
      #end

      # Prepend globals type definition so globals are processed first, allowing everything else to access them
      #
      type_defs = get_defs(:type)
      globals_type_def = type_defs.find{|td| td.id == :globals}
      type_defs.delete(globals_type_def)
      type_defs.prepend(globals_type_def)

      type_defs.each do |d|
        id = d.id
        log "Creating '#{id}' type at #{d.src_loc.src_loc_describe}"
        jt = make_jaba_type(id, d)
        nm = get_or_make_node_manager(id)

        plugins = []
        if !jt.plugin.empty?
          jt.plugin.each do |plugin_id, pb|
            klass = Class.new(Plugin)
            klass.class_eval(&pb)
            plugins << make_plugin(klass, plugin_id, nm)
          end
        else
          plugins << make_plugin(Plugin, id, nm)
        end
        nm.init(jt, plugins)
      end

      @jaba_types.each(&:post_create)
      @jaba_types.jaba_sort_topological!(:dependencies)

      # Make node manager array based on jaba types so node managers are dependency sorted too
      #
      @node_managers = @jaba_types.map{|jt| get_node_manager(jt.defn_id)}

      @node_managers.each do |nm|
        nm.jaba_type.eval_attr_defs
        nm.process
      end

      @node_managers.each do |nm|
        nm.process
        nm.post_process
      end

      # Output definition input data as a json file, before generation. This is raw data as generated from the definitions.
      # Can be used for debugging and testing.
      #
      if input.dump_state?
        dump_jaba_state
      end

      log 'Performing file generation...'

      @node_managers.each(&:generate)
    end
    
    def init_root_paths
      # Initialise build_root from command line, if not present defaults to cwd. 
      #
      input.build_root = if input.build_root.nil?
        @invoking_dir
      else
        input.build_root.to_absolute(base: @invoking_dir, clean: true)
      end

      @jaba_temp_dir = "#{input.build_root}/.jaba"

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
        @invoking_dir if !test_mode?
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
    end

    def set_global_attrs_from_cmdline
      input.global_attrs.each do |name, values|
        values = Array(values).map{|e| e.to_s}

        attr = @globals_node.get_attr(name.to_sym, fail_if_not_found: false)
        if attr.nil?
          JABA.error("'#{name}' attribute not defined in :globals type", want_backtrace: false)
        end

        attr_def = attr.attr_def
        type = attr_def.jaba_attr_type
        case attr_def.variant
        when :single
          if values.size > 1
            JABA.error("'#{name}' attribute only expects one value but #{values.inspect} provided", want_backtrace: false)
          end
          value = type.from_cmdline(values[0], attr_def)
          if attr.type_id == :file || attr.type_id == :dir
            value = value.to_absolute(base: invoking_dir, clean: true) # TODO: need to do this for array/hash elems too
          end
          attr.set(value)
        when :array
          if values.empty?
            JABA.error("'#{name}' array attribute requires one or more values", want_backtrace: false)
          end
          attr.set(values.map{|v| type.from_cmdline(v, attr_def)})
        when :hash
          if values.empty? || values.size % 2 != 0
            JABA.error("'#{name}' hash attribute requires one or more pairs of values", want_backtrace: false)
          end
          key_type = attr.attr_def.jaba_attr_key_type
          values.each_slice(2) do |kv|
            key = key_type.from_cmdline(kv[0], attr_def)
            value = type.from_cmdline(kv[1], attr_def)
            attr.set(key, value)
          end
        end
      end
    end

    def create_core_objects
      constants = JABA.constants(false).sort # Don't iterate directly as constants could get created inside loop
      constants.each do |c|
        case c
        when /^JabaAttributeType./
          make_attr_type(JABA.const_get(c))
        when /^JabaAttrDefFlag./
          make_attr_flag(JABA.const_get(c))
        end
      end
      @jaba_attr_types.sort_by!(&:id)
      @jaba_attr_flags.sort_by!(&:id)
    end

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

    def get_attribute_flag(id)
      f = @jaba_attr_flag_lookup[id]
      if !f
        JABA.error("'#{id.inspect_unquoted}' is an invalid flag. Valid flags: [#{@jaba_attr_flags.map{|at| at.id.inspect}.join(', ')}]")
      end
      f
    end

    def define(what, id, *args, **keyval_args, &block)
      lookup_id = id
      if what == :instance
        type_id = id
        inst_id = args.shift
        lookup_id = "#{type_id}|#{inst_id}" # eg 'cpp|MyApp'
        id = inst_id
      end

      validate_id(id, what)

      log "  Defining '#{what}:#{lookup_id}' at #{$last_call_location.src_loc_describe}"
      
      existing = get_definition(what, lookup_id, fail_if_not_found: false)
      if existing
        JABA.error("'#{lookup_id}' multiply defined. First definition at #{existing.src_loc.src_loc_describe}.")
      end

      d = make_definition(id, block, $last_call_location)
      d.flags.concat(args)
      d.open_defs_lookup_id = lookup_id
      
      def_reg = @definition_registry[what]
      def_reg.defs << d
      def_reg.lookup[lookup_id] = d

      if what == :instance
        d.jaba_type_id = type_id
        nm = get_or_make_node_manager(type_id)
        nm.add_definition(d)
      end
      nil
    end

    def open(what, id, &block)
      validate_id(id, what)
      JABA.error("'#{what.inspect_unquoted}' requires a block") if !block_given?

      log "  Opening '#{what}:#{id}' at #{$last_call_location.src_loc_describe}"

      d = make_definition(id, block, $last_call_location)
      
      def_reg = @open_definitions_registry[what]
      def_reg.defs << d
      def_reg.lookup.push_value(id, d)

      nil
    end

    def validate_id(id, what)
      if !(id.symbol? || id.string?) || id !~ /^[a-zA-Z0-9_\-.|]+$/
        msg = if id.nil?
          "'#{what}' requires an id"
        else
          "'#{id}' is an invalid id"
        end
        msg << ". Must be an alphanumeric string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'"
        JABA.error(msg)
      end
    end

    DefRegistry = Struct.new(:defs, :lookup)

    def register_toplevel_item(*items)
      items.each do |what|
        @definition_registry[what] = DefRegistry.new([], {})
        @open_definitions_registry[what] = DefRegistry.new([], {})
      end
    end

    def get_definition(what, id, fail_if_not_found: true)
      d =  @definition_registry[what].lookup[id]
      if !d && fail_if_not_found
        JABA.error("#{what} definition '#{id.inspect_unquoted}' not defined")
      end
      d
    end

    def get_defs(what) = @definition_registry[what].defs
    def iterate_defs(what, &block) = get_defs(what).each(&block)
    
    Definition = Struct.new(
      :id,
      :block,
      :src_loc,
      :open_defs,
      :open_defs_lookup_id,
      :flags,
      :jaba_type_id # Used by instances
    )
    
    def make_definition(id, block, src_loc)
      d = Definition.new
      d.id = id
      d.block = block
      d.src_loc = src_loc
      d.open_defs = nil
      d.open_defs_lookup_id = nil
      d.flags = []
      d.define_singleton_method(:has_flag?) do |f|
        flags.include?(f)
      end
      d.jaba_type_id = nil
      d
    end

    def make_jaba_type(id, dfn)
      if @jaba_type_lookup.key?(id)
        JABA.error("'#{id}' jaba type multiply defined")
      end

      jt = JabaType.new(self, dfn.id, dfn.src_loc, dfn.block, dfn.open_defs)

      @jaba_types  << jt
      @jaba_type_lookup[id] = jt
      jt
    end

    def get_jaba_type(id, fail_if_not_found: true, errobj: nil)
      jt = @jaba_type_lookup[id]
      if !jt && fail_if_not_found
        JABA.error("'#{id}' type not defined", errobj: errobj)
      end
      jt
    end

    def get_or_make_node_manager(id)
      nm = get_node_manager(id, fail_if_not_found: false)
      if !nm
        nm = NodeManager.new(self)
        @node_manager_lookup[id] = nm
      end
      nm
    end

    def get_node_manager(jaba_type_id, fail_if_not_found: true)
      nm = @node_manager_lookup[jaba_type_id]
      if !nm && fail_if_not_found
        JABA.error("'#{jaba_type_id}' node manager not found")
      end 
      nm
    end

    def get_nodes_of_type(type_id)
      nm = get_node_manager(type_id)
      nm.root_nodes.map{|n| n.attrs_read_only}
    end

    def make_plugin(klass, id, node_manager)
      log "Making #{id} plugin"

      if !klass.ancestors.include?(Plugin)
        JABA.error("#{klass} must subclass Plugin")
      end

      if get_plugin(id, fail_if_not_found: false)
        JABA.error("Duplicate plugin id '#{id}'")
      end

      ps = PluginServices.new
      ps.instance_variable_set(:@services, self)
      ps.instance_variable_set(:@node_manager, node_manager)

      plugin = klass.new
      plugin.instance_variable_set(:@services, ps)
      plugin.instance_variable_set(:@id, id)
      plugin.init

      @plugin_lookup[id] = plugin

      plugin
    end

    def get_plugin(plugin_id, fail_if_not_found: true)
      plugin = @plugin_lookup[plugin_id]
      if !plugin && fail_if_not_found
        JABA.error("'#{plugin_id}' does not exist")
      end
      plugin
    end

    def in_attr_default_block? = @in_attr_default_block
    def execute_attr_default_block(node, default_block)
      @in_attr_default_block = true
      result = nil
      node.make_read_only do # default blocks should not attempt to set another attribute
        result = node.eval_jdl(&default_block)
      end
      @in_attr_default_block = false
      result
    end

    def get_translator(id, fail_if_not_found: true)
      t = @translators[id]
      if !t && fail_if_not_found
        JABA.error("'#{id.inspect_unquoted}' translator not found")
      end
      t
    end

    def register_node(node)
      handle = node.handle
      if @node_lookup.key?(handle)
        JABA.error("Duplicate node handle '#{handle}'")
      end
      @node_lookup[handle] = node
    end

    def node_from_handle(handle, fail_if_not_found: true, errobj: nil)
      n = @node_lookup[handle]
      if !n && fail_if_not_found
        JABA.error("Node with handle '#{handle}' not found", errobj: errobj)
      end
      n
    end

    def register_array_filter(type_id, attr_id, &block)
      jt = get_jaba_type(type_id)
      attr_def = jt.get_attribute_def(attr_id)
      if !attr_def.array?
        JABA.error("Can only register an array filter on array attributes")
      end
      attr_def.set_filter(&block)
    end

    def dump_jaba_state
      root = {}
      root[:jdl_files] = @load_manager.jdl_files

      @node_managers.each do |nm|
        nm.root_nodes.each do |rn|
          obj = {}
          root["#{nm.type_id}|#{rn.handle}"] = obj
          write_node_json(nm, root, rn, obj)
        end
      end
      json = JSON.pretty_generate(root)
      file = @file_manager.new_file('.jaba/jaba.state.json'.to_absolute(base: input.build_root, clean: true), eol: :native, track: false)
      w = file.writer
      w.write_raw(json)
      file.write
    end

    def write_node_json(nm, root, node, obj)
      node.visit_attr(top_level: true) do |attr, val|
        obj[attr.defn_id] = val
      end
      if !node.children.empty?
        node.children.each do |child|
          child_obj = {}
          root["#{nm.type_id}|#{child.handle}"] = child_obj
          write_node_json(nm, root, child, child_obj)
        end
      end
    end

    def build_output
      log 'Building output...'
      
      out_file = "#{@jaba_temp_dir}/jaba.output.#{globals.target_host}.json"

      @generated = @file_manager.generated

      @output[:jaba_version] = VERSION
      @output[:format_version] = 1
      @output[:src_root] = input.src_root
      @output[:build_root] = input.build_root
      @output[:generated] = @generated

      @node_managers.each do |nm|
        nm.build_output(output)
      end

      if input.dump_output?
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
      @unchanged = @file_manager.unchanged.map{|f| f.relative_path_from(input.build_root)}.sort_no_case!

      # These are not included in the output file but are returned to outer context
      #
      @output[:added] = @added
      @output[:modified] = @modified
      @output[:unchanged] = @unchanged
    end

    # This will cause a series of calls to eg define_attr_type, define_type, define_instance (see further
    # down in this file). These calls will come from user definitions via the api files.
    #
    def execute_jdl(*args, file: nil, str: nil, &block)
      if str
        @top_level_api.instance_eval(str, file)
      elsif file
        log "Executing #{file}"
        @top_level_api.instance_eval(file_manager.read(file), file)
      end
      if block_given?
        @top_level_api.instance_exec(*args, &block)
      end
    rescue JabaError
      raise # Prevent fallthrough to next case
    rescue StandardError => e # Catches errors like invalid constants
      JABA.error(e.message, callstack: e.backtrace)
    rescue ScriptError => e # Catches syntax errors. In this case there is no backtrace.
      JABA.error(e.message, syntax: true)
    end

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

    def term_log
      return if !@log_msgs
      log_dir = @jaba_temp_dir ? @jaba_temp_dir : @invoking_dir
      log_fn = "#{log_dir}/jaba.log"
      if File.exist?(log_fn)
        File.delete(log_fn)
      else
        FileUtils.makedirs(log_fn.parent_path)
      end
      IO.write(log_fn, @log_msgs.join("\n"))
    end

    def jaba_warn(msg, errobj: nil, callstack: nil)
      callstack = Array(errobj&.src_loc || callstack || caller)
      jdl_bt = get_jdl_backtrace(callstack)
      if jdl_bt.empty?
        msg = "Warning: #{msg}"
      else
        msg = make_error_info(msg, jdl_bt, err_type: :warning).message
      end
      log(msg, :WARN)
      @warnings << msg
      nil
    end

    def get_jdl_backtrace(callstack)
      # Disregard everything after the main entry point, if it is present in callstack. Prevents error handling from
      # getting confused when definitions are supplied in block form where normal source code and jdl source code
      # exist in the same file.
      #
      jaba_run_idx = callstack.index{|l| l =~ /jaba\/src\/jaba\.rb.*in `run'/}
      if jaba_run_idx
        callstack.slice!(jaba_run_idx..-1)
      end

      candidates = @load_manager.jdl_files

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

    def make_error_info(msg, backtrace, err_type: :error)
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
