# frozen_string_literal: true

# The only ruby library files that Jaba core depends on
require 'digest/sha1'
require 'json'
require 'tsort'

require_relative 'core_ext'
require_relative 'utils'
require_relative 'file_manager'
require_relative 'property'
require_relative 'hook'
require_relative 'jaba_definition'
require_relative 'jaba_object'
require_relative 'jaba_attribute_type'
require_relative 'jaba_attribute_flag'
require_relative 'jaba_attribute_definition'
require_relative 'jaba_attribute'
require_relative 'jaba_attribute_array'
require_relative 'jaba_attribute_hash'
require_relative 'jaba_type'
require_relative 'jaba_node'
require_relative 'generator'
require_relative 'project'
require_relative '../projects/vsproj'
require_relative '../projects/vcxproj'
require_relative '../projects/xcodeproj'
require_relative '../generators/cpp_generator.rb'
require_relative '../generators/text_generator.rb'

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

      # Add cwd to load_paths, unless in the root of jaba itself (ie when developing)
      #
      load_paths = []
      if !File.exist?("#{JABA.cwd}/jaba_root")
        load_paths << JABA.cwd
      end
      @input.instance_variable_set(:@load_paths, load_paths)

      @output = {}
      
      @log_file = nil
      
      @warnings = []
      @warn_object = nil
      
      @definition_src_files = []
      
      @jaba_attr_type_definitions = []
      @jaba_attr_flag_definitions = []
      @jaba_type_definitions = []
      @jaba_open_definitions = []
      @default_definitions = []
      @instance_definitions = []
      @instance_definition_lookup = {}
      @shared_definition_lookup = {}

      @current_definition = nil

      @jaba_attr_types = []
      @jaba_attr_flags = []
      @jaba_types = []
      @jaba_type_lookup = {}

      @generators = []

      @nodes = []
      @node_lookup = {}
      @root_nodes = []
      @null_nodes = {}
      @reference_attrs_to_resolve = []
      
      @in_attr_default_block = false
      @building_jaba_output = false

      @top_level_api = JabaTopLevelAPI.new(self)
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
      # Load and execute any definition files specified in Input#load_paths
      #
      gather_definition_src_files

      @definition_src_files.each do |f|
        execute_definitions(f)
      end

      # Execute any definitions supplied inline in a block
      #
      Array(input.definitions).each do |block|
        execute_definitions(&block)
      end
      
      # Create attribute types
      #
      @jaba_attr_type_definitions.each do |d|
        @jaba_attr_types << JabaAttributeType.new(self, d)
      end
      
      # Create attribute flags, which are used in attribute definitions
      #
      @jaba_attr_flag_definitions.each do |d|
        @jaba_attr_flags << JabaAttributeFlag.new(self, d)
      end

      # Create JabaTypes and any associated Generators
      #
      @jaba_type_definitions.each do |d|
        make_type(d.id, d)
      end

      # Open JabaTypes so more attributes can be added
      #
      @jaba_open_definitions.each do |d|
        get_jaba_type(d.id, callstack: d.source_location).eval_api_block(&d.block)
      end
      
      # When an attribute defined in a JabaType will reference a differernt JabaType a dependency on that
      # type is added. JabaTypes are dependency order sorted to ensure that referenced JabaNodes are created
      # before the JabaNode that are referencing it.
      #
      @jaba_types.each do |jt|
        jt.resolve_dependencies
        jt.register_referenced_attributes
      end
      
      begin
        @jaba_types.sort_topological!(:dependencies)
      rescue TSort::Cyclic => e
        err_type = e.instance_variable_get(:@err_obj)
        jaba_error("'#{err_type}' contains a cyclic dependency", callstack: err_type.definition.source_location)
      end
      
      # Now that the JabaTypes are dependency sorted, pass on the dependency ordering to the JabaNodes.
      # This is achieved by giving each JabaType an index and then sorting nodes based on this index.
      # The sort is stable so as to preserve the order that was specified in definition files.
      #
      @jaba_types.each_with_index {|jt, i| jt.instance_variable_set(:@order_index, i)}

      log 'Initialisation of JabaTypes complete'

      # Associate a JabaType with each instance of a type.
      #
      @instance_definitions.each do |d|
        d.instance_variable_set(:@jaba_type, get_jaba_type(d.jaba_type_id, callstack: d.source_location))
      end
      
      @instance_definitions.stable_sort_by! {|d| d.jaba_type.instance_variable_get(:@order_index)}
      
      # Create instances of JabaNode from JabaTypes. This could be a single node or a tree of nodes.
      # Track the root node that is returned in each case. The array of root nodes is used to dump definition data to json.
      #
      @instance_definitions.each do |d|
        log "Processing #{d.jaba_type.handle} #{d.id} definition", section: true
        @current_definition = d

        g = d.jaba_type.generator
        @root_nodes << if g
                         g.make_nodes
                       else
                         make_node
                       end
      end
      
      log 'Initialisation of JabaNodes complete'

      @globals_node = node_from_handle('globals|globals')

      log "Resolving references..."

      # Resolve references
      #
      @reference_attrs_to_resolve.each do |a|
        a.map_value! do |ref|
          resolve_reference(a, ref)
        end
      end
      
      log 'Making projects...'

      # Call generators to build project representations from nodes
      #
      @generators.each(&:make_projects)

      @nodes.each do |n|
        n.each_attr do |a|
          a.process_flags
        end
        
        # Make all nodes read only from this point, to help catch mistakes
        #
        n.make_read_only
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
      @generators.each(&:generate)

      # Call generators defined per-node instance, in the context of the node itself, not its api
      #
      @root_nodes.each do |n|
        # TODO: review again. should it use api?
        n.definition.call_hook(:generate, receiver: n, use_api: false)
      end

      log 'Building output...'
      build_jaba_output
    end
    
    ##
    #
    def define_attr_type(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Defining attr type [id=#{id}]"
      validate_id(id)
      existing = @jaba_attr_type_definitions.find{|d| d.id == id}
      if existing
        jaba_error("Attribute type '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      @jaba_attr_type_definitions << JabaDefinition.new(id, block, caller_locations(2, 1)[0])
      nil
    end

    ##
    #
    def define_attr_flag(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Defining attr flag [id=#{id}]"
      validate_id(id)
      existing = @jaba_attr_flag_definitions.find{|d| d.id == id}
      if existing
        jaba_error("Attribute flag '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      @jaba_attr_flag_definitions << JabaDefinition.new(id, block, caller_locations(2, 1)[0])
      nil
    end

    ##
    #
    def define_type(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Defining type [id=#{id}]"
      validate_id(id)
      existing = @jaba_type_definitions.find{|d| d.id == id}
      if existing
        jaba_error("Type '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      @jaba_type_definitions << JabaDefinition.new(id, block, caller_locations(2, 1)[0])
    end
    
    ##
    #
    def open_type(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Opening type [id=#{id}]"
      jaba_error("a block is required") if !block_given?
      @jaba_open_definitions << JabaDefinition.new(id, block, caller_locations(2, 1)[0])
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

      @shared_definition_lookup[id] = JabaDefinition.new(id, block, caller_locations(2, 1)[0])
      nil
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
      @instance_definition_lookup.push_value(type_id, d)
      @instance_definitions << d
      nil
    end
    
    ##
    #
    def define_defaults(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Defining defaults [id=#{id}]"
      existing = @default_definitions.find {|d| d.id == id}
      if existing
        jaba_error("Defaults block '#{id.inspect_unquoted}' multiply defined. See #{existing.src_loc_basename}.")
      end
      @default_definitions << JabaDefinition.new(id, block, caller_locations(2, 1)[0])
      nil
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
    def make_generator(id)
      gen_classname = "#{id.to_s.capitalize_first}Generator"
      
      return nil if !JABA.const_defined?(gen_classname)

      klass = JABA.const_get(gen_classname)

      if klass.superclass != Generator
        jaba_error "#{klass} must inherit from Generator class"
      end

      g = klass.new(self, id)
      @generators << g
      g
    end

    ##
    # JabaTypes can have some of their attributes split of into separate JabaTypes to help with node
    # creation in the case where a tree of nodes is created from a single definition. These JabaTypes
    # are created on the fly as attributes are added to the types.
    #
    def make_type(handle, definition, parent: nil, &block)
      log "Instancing JabaType [handle=#{handle}]"

      if @jaba_type_lookup.key?(handle)
        jaba_error("'#{handle}' jaba type multiply defined")
      end

      jt = nil

      if parent
        jt = JabaType.new(self, definition, handle, parent)
        if block_given?
          jt.eval_api_block(&block)
        end
      else
        # Generator is only created if one exists for the type, otherwise it is nil
        #
        g = make_generator(definition.id)
        dd = get_defaults_definition(definition.id)

        jt = TopLevelJabaType.new(self, definition, handle, g, dd)
        @jaba_types  << jt

        if definition.block
          jt.eval_api_block(&definition.block)
        end
      end

      @jaba_type_lookup[handle] = jt
      jt
    end

    ##
    #
    def make_node(type_id: @current_definition.jaba_type_id, name: nil, parent: nil, &block)
      depth = 0
      handle = nil

      if parent
        jaba_error('name is required for child nodes') if !name
        if name.is_a?(JabaNode)
          name = name.definition_id
        end
        handle = "#{parent.handle}|#{name}"
        depth = parent.depth + 1
      else
        jaba_error('name not required for root nodes') if name
        depth = 0
        handle = "#{@current_definition.jaba_type_id}|#{@current_definition.id}"
      end

      log "#{'  ' * depth}Instancing node [type=#{type_id}, handle=#{handle}]"

      if node_from_handle(handle, fail_if_not_found: false)
        jaba_error("Duplicate node handle '#{handle}'")
      end

      jt = get_jaba_type(type_id)

      jn = JabaNode.new(self, @current_definition, jt, handle, parent, depth)

      @nodes << jn
      @node_lookup[handle] = jn
      
      begin
        # Give calling block a chance to initialise attributes. This block is in library code as opposed to user
        # definitions so use instance_eval instead of eval_api_block, as it doesn't need to go through api.
        # Read only attributes are allowed to be set (initialised) for the duration of this block.
        #
        if block_given?
          jn.allow_set_read_only_attrs do
            jn.attrs.instance_eval(&block)
          end
        end
        
        # Next execute defaults block if there is one defined for this type.
        #
        defaults = jt.top_level_type.defaults_definition
        if defaults
          jn.eval_api_block(&defaults.block)
        end

        if @current_definition.block
          jn.eval_api_block(&@current_definition.block)
        end
      rescue FrozenError => e
        jaba_error('Cannot modify read only value', callstack: e.backtrace)
      end

      jn.post_create
      jn
    end
    
    ##
    # Given a reference attribute and the definition id it is pointing at, returns the node instance.
    #
    def resolve_reference(attr, ref_node_id, ignore_if_same_type: false)
      attr_def = attr.attr_def
      node = attr.node
      rt = attr_def.referenced_type
      if ignore_if_same_type && rt == node.jaba_type.definition_id
        @reference_attrs_to_resolve << attr
        return ref_node_id
      end
      make_handle_block = attr_def.get_property(:make_handle)
      handle = if make_handle_block
        "#{rt}|#{node.eval_api_block(ref_node_id, &make_handle_block)}"
      else
        "#{rt}|#{ref_node_id}"
      end
      ref_node = node_from_handle(handle, callstack: attr.last_call_location)
      
      # Don't need to track node references when resolving references between the same types as this
      # happens after all the nodes have been set up, by which time the functionality is not needed.
      # The node references are used in the attribute search path in JabaNode#get_attr.
      #
      if ignore_if_same_type 
        node.add_node_reference(ref_node)
      end
      ref_node
    end

    ##
    #
    def node_from_handle(handle, fail_if_not_found: true, callstack: nil)
      n = @node_lookup[handle]
      if !n && fail_if_not_found
        jaba_error("Node with handle '#{handle}' not found", callstack: callstack)
      end
      n
    end

    ##
    #
    def in_attr_default_block?
      @in_attr_default_block
    end#

    ##
    #
    def execute_attr_default_block(node, default_block)
      @in_attr_default_block = true
      result = nil
      node.make_read_only do # default blocks should not attempt to set another attribute
        result = node.eval_api_block(&default_block)
      end
      @in_attr_default_block = false
      result
    end

    ##
    #
    def get_null_node(type_id)
      nn = @null_nodes[type_id]
      if !nn
        jt = get_jaba_type(type_id)
        nn = JabaNode.new(self, jt.definition, jt, "Null#{jt.definition_id}", nil, 0)
        @null_nodes[type_id] = nn
      end
      nn
    end

    ##
    #
    def dump_jaba_input
      root = {}
      nodes_root = {}
      root[:definition_src] = @definition_src_files
      root[:nodes] = nodes_root
      @root_nodes.each do |rn|
        obj = {}
        nodes_root[rn.handle] = obj
        write_node_json(rn, obj)
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
        obj[attr.definition_id] = val
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
    def building_jaba_output?
      @building_jaba_output
    end

    ##
    #
    def build_jaba_output
      @building_jaba_output = true

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
          g_root = {}

          # Namespace each generator. Each node handle prefix is removed to acount for this, eg cpp|MyApp|vs2019|windows
          # becomes MyApp|vs2019|windows and goes inside a 'cpp' json element.
          #
          @output[g.type_id] = g_root
          g.build_jaba_output(g_root, out_dir)
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

      @building_jaba_output = false
    end

    ##
    #
    def get_attribute_type(id)
      if id.nil?
        return @default_attr_type
      end
      t = @jaba_attr_types.find {|at| at.definition_id == id}
      if !t
        jaba_error("'#{id}' attribute type is undefined. Valid types: #{@jaba_attr_types.map(&:definition_id)}")
      end
      t
    end
    
    ##
    #
    def get_attribute_flag(id)
      f = @jaba_attr_flags.find {|af| af.definition_id == id}
      if !f
        jaba_error("'#{id.inspect_unquoted}' is an invalid flag. Valid flags: #{@jaba_attr_flags.map(&:definition_id)}")
      end
      f
    end

    ##
    #
    def get_jaba_type(id, fail_if_not_found: true, callstack: nil)
      jt = @jaba_type_lookup[id]
      if !jt && fail_if_not_found
        jaba_error("'#{id}' type not defined", callstack: callstack)
      end
      jt
    end
    
    ##
    #
    def get_instance_definition(type_id, id, fail_if_not_found: true)
      defs = @instance_definition_lookup[type_id]
      return nil if !defs
      d = defs.find {|dd| dd.id == id}
      if !d && fail_if_not_found
        jaba_error("No '#{id}' definition found")
      end
      d
    end

    ##
    #
    def get_instance_ids(type_id)
      defs = @instance_definition_lookup[type_id]
      if !defs
        jaba_error("No '#{type_id}' type defined")
      end
      defs.map(&:id)
    end
    
    ##
    #
    def get_shared_definition(id, fail_if_not_found: true)
      d = @shared_definition_lookup[id]
      if !d && fail_if_not_found
        jaba_error("Shared definition '#{id}' not found")
      end
      d
    end

    ##
    #
    def get_defaults_definition(id)
      @default_definitions.find {|d| d.id == id}
    end

    ##
    #
    def execute_definitions(file = nil, &block)
      if file
        log "Executing #{file}"
        @top_level_api.instance_eval(@file_manager.read_file(file), file)
      end
      if block_given?
        @definition_src_files << block.source_location[0]
        @top_level_api.instance_eval(&block)
      end
    rescue JabaDefinitionError
      raise # Prevent fallthrough to next case
    rescue StandardError => e # Catches errors like invalid constants
      jaba_error(e.message, callstack: e.backtrace)
    rescue ScriptError => e # Catches syntax errors. In this case there is no backtrace.
      jaba_error(e.message, syntax: true)
    end
    
    ##
    #
    def gather_definition_src_files
      # Load core type definitions 
      @definition_src_files.concat(@file_manager.glob("#{__dir__}/../definitions/*.rb".cleanpath))
      
      Array(input.load_paths).each do |p|
        p = p.to_absolute(clean: true)

        if !File.exist?(p)
          jaba_error("#{p} does not exist")
        end

        # If load path is a directory, if its called 'jaba' then load all files recursively,
        # else search all files recursively and load any called jaba.rb.
        # 
        if File.directory?(p)
          match = if p.basename == 'jaba'
                    "#{p}/**/*.rb"
                  else
                    "#{p}/**/jaba.rb"
                  end
          files = @file_manager.glob(match)
          if files.empty?
            jaba_warning("No definition files found in #{p}")
          else
            @definition_src_files.concat(files)
          end
        else
          @definition_src_files << p
        end
      end
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
        options[:callstack] = @warn_object.is_a?(JabaObject) ? @warn_object.definition.source_location : @warn_object
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
    #    execute_definitions.
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
        lines = backtrace.select {|c| @definition_src_files.any? {|sf| c.include?(sf)}}

        # remove the unwanted ':in ...' suffix from user level definition errors
        #
        lines.map!{|l| l.sub(/:in .*/, '')}
        
        # If no references to definition files assume the error came from internal library code and raise a RuntimeError,
        # unless its specifically flagged as a user error, which can happen when validating jaba input, before any
        # definitions are executed.
        #
        if lines.empty?
          e = if user_error
                e = JabaDefinitionError.new(msg)
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
      
      e = JabaDefinitionError.new(m)
      e.instance_variable_set(:@raw_message, msg)
      e.instance_variable_set(:@file, file)
      e.instance_variable_set(:@line, line)
      e.set_backtrace(lines)
      e
    end

  end

end
