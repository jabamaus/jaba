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
require_relative '../extend/plugin'
require_relative '../extend/src'
require_relative '../extend/vsproj'
require_relative 'node_manager'

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
      @input.instance_variable_set(:@global_attrs, {})
      @input.instance_variable_set(:@dump_output, true)
      @output = {}
      
      @log_msgs = JABA.running_tests? ? nil : [] # Disable logging when running tests
      @warnings = []
      
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
      @node_lookup = {}
      @plugin_lookup = {}

      @jaba_attr_types = []
      @jaba_attr_type_lookup = {}
      @jaba_attr_flags = []
      @jaba_attr_flag_lookup = {}
      @jaba_types = []
      @jaba_type_lookup = {}
      @translators = {}

      @globals_type_def = nil
      @globals = nil
      @globals_node = nil

      @null_attr_type = JabaAttributeType.new(:null, 'Null attribute type')
      
      @in_attr_default_block = false
      @processing_jaba_types = false

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

      summary = "Generated #{@generated.size} files, #{@added.size} added, #{@modified.size} modified, #{@unchanged.size} unchanged in #{duration}"
      summary << " [dry run]" if input.dry_run?
      summary << "\n"

      @added.each do |f|
        summary << "  #{f} [A]\n"
      end
      @modified.each do |f|
        summary << "  #{f} [M]\n"
      end
      if input.verbose
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

    ##
    #
    def do_run
      if input_manager.cmd_specified?(:help)
        url = "#{JABA.jaba_docs_url}/v#{VERSION}"
        cmd = if OS.windows?
          'start'
        elsif OS.mac?
          'open'
        else
          JABA.error("Unsupported platform")
        end
        system("#{cmd} #{url}")
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

      # Create JabaTypes and any associated plugins
      #
      @jaba_type_defs.each do |d|
        make_jaba_type(d.id, d)
      end

      # Open JabaTypes so more attributes can be added
      #
      @open_type_defs.each do |d|
        log "Opening #{d.id} type"
        jt = get_jaba_type(d.id, errobj: d)
        jt.eval_jdl(&d.block)
      end

      @jaba_types.each(&:post_create)

      # When an attribute defined in a JabaType will reference a differernt JabaType a dependency on that
      # type is added. JabaTypes are dependency order sorted to ensure that referenced JabaNodes are created
      # before the JabaNode that are referencing it.
      #
      @jaba_types.sort_topological!(:dependencies)

      log 'Initialisation of JabaTypes complete'

      # Process instance definitions and assign them to a top level type/node manager
      #
      @instance_defs.each do |d|
        jt = get_jaba_type(d.jaba_type_id, errobj: d)
        jt.node_manager.register_instance_definition(d)
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

      @processing_jaba_types = true

      # Process globals first as everything should have access to them. Globals have no dependencies.
      # See GlobalsPlugin.
      #
      globals_type = @jaba_types.first
      globals_type.node_manager.process

      1.upto(@jaba_types.size-1) do |i|
        @jaba_types[i].node_manager.process
      end

      @processing_jaba_types = false

      # Output definition input data as a json file, before generation. This is raw data as generated from the definitions.
      # Can be used for debugging and testing.
      #
      if input.dump_state
        dump_jaba_state
      end

      log 'Performing file generation...'

      # Write final files
      #
      @jaba_types.each do |jt|
        # Call generate blocks defined per-node instance, in the context of the node itself, not its api
        #
        jt.node_manager.root_nodes.each do |n|
          n.call_hook(:generate, receiver: n, use_api: false)
        end
        jt.plugin.generate
      end
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
        values = Array(values).map{|e| e.to_s}

        attr = @globals_node.get_attr(name.to_sym, fail_if_not_found: false)
        if attr.nil?
          @input_manager.usage_error("'#{name}' attribute not defined in :globals type")
        end

        attr_def = attr.attr_def
        type = attr_def.jaba_attr_type
        case attr_def.variant
        when :single
          if values.size > 1
            @input_manager.usage_error("'#{name}' attribute only expects one value but #{values.inspect} provided")
          end
          value = type.from_cmdline(values[0], attr_def)
          if attr.type_id == :file || attr.type_id == :dir
            value = value.to_absolute(base: invoking_dir, clean: true) # TODO: need to do this for array/hash elems too
          end
          attr.set(value)
        when :array
          if values.empty?
            @input_manager.usage_error("'#{name}' array attribute requires one or more values")
          end
          attr.set(values.map{|v| type.from_cmdline(v, attr_def)})
        when :hash
          if values.empty? || values.size % 2 != 0
            @input_manager.usage_error("'#{name}' hash attribute requires one or more pairs of values")
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
        when /^(.+)Plugin$/
          # Create non-default plugins up front (eg CppPlugin, WorkspacePlugin). There will only be one instance
          # of each of these. DefaultPlugins will be created later as there will be one created for each jaba type that
          # has not defined its own plugin. Creating plugins up front allows plugins to register early with the
          # system.
          #
          next if c == :DefaultPlugin
          
          id = Regexp.last_match(1)
          klass = JABA.const_get(c)
          plugin = make_plugin(klass)
          @plugin_lookup[id] = plugin
        end
      end
      @jaba_attr_types.sort_by!(&:id)
      @jaba_attr_flags.sort_by!(&:id)
    end

    ##
    #
    def make_plugin(klass)
      ps = PluginServices.new
      ps.instance_variable_set(:@services, self)

      nm = NodeManager.new(self)
      ps.instance_variable_set(:@node_manager, nm)

      plugin = klass.new
      plugin.instance_variable_set(:@services, ps)
      nm.instance_variable_set(:@plugin, plugin)

      plugin.init
      plugin
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
    def make_definition(id, block, src_loc, flags=[])
      d = OpenStruct.new
      d.id = id
      d.block = block
      d.src_loc = src_loc
      d.open_defs = []
      d.jaba_type_id = nil
      d.flags = flags
      d.define_singleton_method(:has_flag?) do |f|
        flags.include?(f)
      end
      d
    end

    ##
    #
    def make_jaba_type(id, dfn)
      log "Creating '#{id}' type at #{dfn.src_loc.describe}"

      if @jaba_type_lookup.key?(id)
        JABA.error("'#{id}' jaba type multiply defined")
      end

      plugin_id = id.to_s.capitalize_first # egg Cpp/Workspace
      plugin = @plugin_lookup[plugin_id]
      if !plugin
        plugin = make_plugin(DefaultPlugin)
      end

      nm = plugin.services.instance_variable_get(:@node_manager)
      jt = JabaType.new(self, dfn.id, dfn.src_loc, dfn.block, plugin, nm)
      nm.set_jaba_type(jt)

      @jaba_types  << jt
      @jaba_type_lookup[id] = jt

      jt
    end

    ##
    #
    def get_jaba_type(id, fail_if_not_found: true, errobj: nil)
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
      src_loc = caller_locations(2, 1)[0]
      log "  Defining '#{id}' type at #{src_loc.describe}"
      validate_id(id)
      existing = @jaba_type_defs.find{|d| d.id == id}
      if existing
        JABA.error("'type|#{id.inspect_unquoted}' multiply defined. First definition at #{existing.src_loc.describe}.")
      end
      d = make_definition(id, block, src_loc)
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

      src_loc = caller_locations(2, 1)[0]

      log "  Defining '#{id}' shared definition at #{src_loc.describe}"
      validate_id(id)

      existing = get_shared_definition(id, fail_if_not_found: false)
      if existing
        JABA.error("'shared|#{id.inspect_unquoted}' multiply defined. First definition at #{existing.src_loc.describe}.")
      end

      @shared_def_lookup[id] = make_definition(id, block, src_loc)
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
    def define_instance(type_id, id, flags=[], &block)
      JABA.error("type_id is required") if type_id.nil?
      JABA.error("id is required") if id.nil?

      validate_id(id)

      src_loc = caller_locations(2, 1)[0]

      log "  Defining '#{id}' instance [type=#{type_id}] at #{src_loc.describe}"

      existing = get_instance_definition(type_id, id, fail_if_not_found: false)
      if existing
        JABA.error("'#{type_id}|#{id.inspect_unquoted}' multiply defined. First definition at #{existing.src_loc.describe}.")
      end
      
      d = make_definition(id, block, src_loc, flags)
      d.jaba_type_id = type_id

      @instance_def_lookup.push_value(type_id, d)

      # Plugins are allowed to create more instances while they are being processed. eg the cpp plugin
      # automatically creates workspaces. If jaba types are already being processed create the instance
      # immediately, otherwise save for later (as jaba types will not have been created yet).
      #
      if @processing_jaba_types
        jt = get_jaba_type(d.jaba_type_id, errobj: d)
        jt.node_manager.register_instance_definition(d)
      else
        @instance_defs << d
      end
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
      src_loc = caller_locations(2, 1)[0]
      log "  Defining '#{id}' defaults at #{src_loc.describe}"
      existing = @default_defs.find {|d| d.id == id}
      if existing
        JABA.error("'defaults|#{id.inspect_unquoted}' multiply defined. First definition at #{existing.src_loc.describe}.")
      end
      @default_defs << make_definition(id, block, src_loc)
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
      src_loc = caller_locations(2, 1)[0]
      log "  Defining '#{id}' translator at #{src_loc.describe}"
      existing = get_translator_definition(id, fail_if_not_found: false)
      if existing
        JABA.error("'translator|#{id.inspect_unquoted}' multiply defined. First definition at #{existing.src_loc.describe}.")
      end
      @translator_defs << make_definition(id, block, src_loc)
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
        log "  Opening '#{id}' type at #{src_loc.describe}"
        @open_type_defs << make_definition(id, block, src_loc)
      when :instance
        log "  Opening '#{id}' instance [type=#{type}] at #{src_loc.describe}"
        JABA.error("type is required") if type.nil?
        d = make_definition(id, block, src_loc)
        d.jaba_type_id = type
        @open_instance_defs << d
      when :translator
        log "  Opening '#{id}' translator at #{src_loc.describe}"
        @open_translator_defs << make_definition(id, block, src_loc)
      when :shared
        log "  Opening '#{id}' shared definition at #{src_loc.describe}"
        @open_shared_defs << make_definition(id, block, src_loc)
      end
      nil
    end

    ##
    #
    def register_node(node)
      handle = node.handle
      if @node_lookup.key?(handle)
        JABA.error("Duplicate node handle '#{handle}'")
      end
      @node_lookup[handle] = node
    end

    ##
    #
    def node_from_handle(handle, fail_if_not_found: true, errobj: nil)
      n = @node_lookup[handle]
      if !n && fail_if_not_found
        JABA.error("Node with handle '#{handle}' not found", errobj: errobj)
      end
      n
    end

    ##
    # Called from JDL API.
    #
    def glob(spec, &block)
      jaba_file_dir = caller_locations(2, 1)[0].absolute_path.parent_path
      if !spec.absolute_path?
        spec = "#{jaba_file_dir}/#{spec}"
      end
      files = @file_manager.glob_files(spec)
      files = files.map{|f| f.relative_path_from(jaba_file_dir)}
      files.each(&block)
    end

    ##
    #
    def get_plugin(jaba_type_id)
      jt = get_jaba_type(jaba_type_id)
      jt.plugin
    end

    ##
    #
    def dump_jaba_state
      root = {}
      root[:jdl_files] = @jdl_files

      @jaba_types.each do |jt|
        jt.node_manager.root_nodes.each do |rn|
          obj = {}
          root["#{p.type_id}|#{rn.handle}"] = obj
          write_node_json(p, root, rn, obj)
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
    def write_node_json(plugin, root, node, obj)
      node.visit_attr(top_level: true) do |attr, val|
        obj[attr.defn_id] = val
      end
      if !node.children.empty?
        node.children.each do |child|
          child_obj = {}
          root["#{plugin.type_id}|#{child.handle}"] = child_obj
          write_node_json(plugin, root, child, child_obj)
        end
      end
    end

    ##
    #
    def build_jaba_output
      log 'Building output...'
      
      out_file = "#{@jaba_temp_dir}/jaba.output.#{globals.target_host}.json"

      @generated = @file_manager.generated

      @output[:jaba_version] = VERSION
      @output[:format_version] = 1
      @output[:src_root] = input.src_root
      @output[:build_root] = input.build_root
      @output[:generated] = @generated

      @jaba_types.each do |jt|
        next if jt.plugin.is_a?(DefaultPlugin)
        root = {}
        jt.plugin.build_jaba_output(root)
        if !root.empty?
          @output[jt.defn_id] = root
        end
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

    ##
    #
    def include_jaba_path(path, base:)
      if base == :grab_bag
        if path.absolute_path?
          JABA.error("'#{path}' must not be absolute if basing it on jaba grab_bag directory")
        end
        path = "#{JABA.grab_bag_dir}/#{path}"
      elsif !path.absolute_path?
        src_loc = caller_locations(2, 1)[0]
        path = "#{src_loc.absolute_path.parent_path}/#{path}"
      end
      if path.wildcard?
        @jdl_includes.concat(Dir.glob(path))
      else
        @jdl_includes << path
      end
    end

    ##
    # This will cause a series of calls to eg define_attr_type, define_type, define_instance (see further
    # down in this file). These calls will come from user definitions via the api files.
    #
    def execute_jdl(file: nil, str: nil, &block)
      if str
        @top_level_api.instance_eval(str, file)
      elsif file
        log "Executing #{file}"
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
        begin
          require f
        rescue ScriptError => e
          JABA.error("Failed to load #{f}: #{e.message}")
        end
      end
    end

    ##
    #
    def load_jaba_files
      if input.barebones? # optimisation for unit testing
        process_jaba_file("#{JABA.modules_dir}/core/globals.jaba")
        process_jaba_file("#{JABA.modules_dir}/core/hosts.jaba")
      else
        @@module_jaba_files.each do |f|
          process_jaba_file(f)
        end
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
      !@file_manager.glob_files("#{path}/*.jaba").empty?
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
        files = @file_manager.glob_files("#{p}/*.jaba")
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
        # Already included. Ignore.
        return
      end
      
      @jdl_file_lookup[f] = nil
      @jdl_files << f

      execute_jdl(file: f)
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
        FileUtils.makedirs(log_fn.parent_path)
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
