# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'json'
require_relative 'core_ext'
require_relative 'utils'
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
require_relative 'vsproject'
require_relative 'vcxproj'

Dir.glob("#{__dir__}/../generators/*_generator.rb").sort.each {|f| require f}

##
#
module JABA

  using JABACoreExt

  ##
  #
  class Services

    attr_reader :input

    @@file_cache = {}
    @@glob_cache = {}

    ##
    #
    def initialize
      @input = Input.new
      @input.instance_variable_set(:@definitions, nil)
      @input.instance_variable_set(:@load_paths, Dir.getwd)
      @input.instance_variable_set(:@jaba_input_file, 'jaba.input.json')
      @input.instance_variable_set(:@dump_input, false)
      @input.instance_variable_set(:@jaba_output_file, 'jaba.output.json')
      @input.instance_variable_set(:@dump_output, true)
      @input.instance_variable_set(:@dry_run, false)
      @input.instance_variable_set(:@enable_logging, false)
      @input.instance_variable_set(:@use_file_cache, false)
      @input.instance_variable_set(:@use_glob_cache, false)

      @output = {}
      
      @logger = nil
      
      @warnings = []
      
      @definition_src_files = []
      
      @generated_files = []
      @generated_files_lookup = {}
      
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
      
      @top_level_api = TopLevelAPI.new(self)

      @default_attr_type = JabaAttributeType.new(self, JabaDefinition.new(nil, nil, caller(0, 1)[0])).freeze
    end

    ##
    #
    def define_attr_type(id, &block)
      jaba_error("id is required") if id.nil?
      log "Registering attr type [id=#{id}]"
      validate_id(id)
      # TODO: check for dupes
      @jaba_attr_type_definitions << JabaDefinition.new(id, block, caller(2, 1)[0])
    end

    ##
    #
    def define_attr_flag(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Registering attr flag [id=#{id}]"
      validate_id(id)
      # TODO: check for dupes
      @jaba_attr_flag_definitions << JabaDefinition.new(id, block, caller(2, 1)[0])
    end

    ##
    #
    def define_type(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Registering type [id=#{id}]"
      validate_id(id)
      # TODO: check for dupes
      @jaba_type_definitions << JabaTypeDefinition.new(id, block, caller(2, 1)[0])
    end
    
    ##
    #
    def open_type(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Opening type [id=#{id}]"
      jaba_error("a block is required") if !block_given?
      @jaba_open_definitions << JabaTypeDefinition.new(id, block, caller(2, 1)[0])
    end
    
    ##
    #
    def define_shared(id, &block)
      jaba_error("id is required") if id.nil?
      jaba_error("a block is required") if !block_given?

      log "  Registering shared definition block [id=#{id}]"
      validate_id(id)

      if get_shared_definition(id, fail_if_not_found: false)
        jaba_error("'#{id}' multiply defined")
      end

      @shared_definition_lookup[id] = JabaDefinition.new(id, block, caller(2, 1)[0])
    end

    ##
    #
    def define_instance(type_id, id, &block)
      jaba_error("type_id is required") if type_id.nil?
      jaba_error("id is required") if id.nil?

      validate_id(id)

      log "  Registering instance [id=#{id}, type=#{type_id}]"

      if instanced?(type_id, id)
        jaba_error("'#{id}' multiply defined")
      end
      
      d = JabaInstanceDefinition.new(id, type_id, block, caller(2, 1)[0])
      @instance_definition_lookup.push_value(type_id, d)
      @instance_definitions << d
    end
    
    ##
    #
    def define_defaults(id, &block)
      jaba_error("id is required") if id.nil?
      log "  Registering defaults [id=#{id}]"
      existing = @default_definitions.find {|d| d.id == id}
      if existing
        jaba_error("'#{id}' defaults multiply defined")
      end
      @default_definitions << JabaDefinition.new(id, block, caller(2, 1)[0])
    end

    ##
    #
    def validate_id(id)
      if !(id.is_a?(Symbol) || id.is_a?(String)) || id !~ /^[a-zA-Z0-9_.]+$/
        jaba_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
          "(underscore permitted), eg :my_id or 'my_id'")
      end
    end

    ##
    #
    def run
      # Set up logger
      #
      if input.enable_logging?
        init_logger
      end
      
      # Load and execute any definition files specified in Input#load_paths
      #
      load_definitions

      # Execute any definitions supplied inline in a block
      #
      if input.definitions
        execute_definitions(&input.definitions)
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
        d.instance_variable_set(:@defaults_definition, get_defaults_definition(d.id))
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
      @jaba_types.each(&:resolve_dependencies)
      
      begin
        @jaba_types.sort_topological!(:dependencies)
      rescue TSort::Cyclic => e
        err_type = e.instance_variable_get(:@err_obj)
        jaba_error("'#{err_type}' contains a cyclic dependency", callstack: err_type.definition.source_location)
      end
      
      @jaba_type_definitions.each(&:register_referenced_attributes)

      log 'Initialisation of JabaTypes complete', section: true
      
      # Now that the JabaTypes are dependency sorted, pass on the dependency ordering to the JabaNodes.
      # This is achieved by giving each JabaType an index and then sorting nodes based on this index.
      # The sort is stable so as to preserve the order that was specified in definition files.
      #
      @jaba_types.each_with_index {|jt, i| jt.instance_variable_set(:@order_index, i)}
      
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
        @current_definition = d

        g = d.jaba_type.generator
        @root_nodes << if g
                         g.make_nodes
                       else
                         make_node
                       end
      end
      
      log "Resolving references..."

      # Resolve references
      #
      @nodes.each do |n|
        n.visit_attr(type: :reference) do |a|
          a.map_value! do |ref|
            if ref && !ref.is_a?(JabaNode)
              resolve_reference(a, ref)
            else
              ref
            end
          end
        end
      end
      
      # Output definition input data as a json file, before generation. This is raw data as generated from the definitions.
      # Can be used for debugging and testing.
      #
      if input.dump_input?
        dump_jaba_input
      end

      log 'Calling generators...'

      # Call generators to build project representations from nodes
      #
      @generators.each(&:make_projects)

      # Make all nodes read only from this point, to help catch mistakes
      #
      @nodes.each(&:make_read_only)
      
      # Write final files
      #
      @generators.each(&:generate)

      # Call generators defined per-node instance, in the context of the node itself, not its api
      #
      @root_nodes.each do |n|
        gh = n.definition.generate_hook
        if gh
          n.instance_eval(&gh) # TODO: review again. should it be api eval?
        end
      end

      dump_jaba_output

      @logger&.close
      
      @output
    end
    
    ##
    #
    def make_generator(id)
      gen_classname = "#{id.to_s.capitalize_first}Generator"
      
      return nil if !JABA.const_defined?(gen_classname)

      log "Making generator [id=#{id}]"
      generator_class = JABA.const_get(gen_classname)

      if generator_class.superclass != Generator
        jaba_error "#{generator_class} must inherit from Generator class"
      end

      g = generator_class.new(self, id)
      @generators << g
      g
    end

    ##
    # JabaTypes can have some of their attributes split of into separate JabaTypes to help with node
    # creation in the case where a tree of nodes is created from a single definition. These JabaTypes
    # are created on the fly as attributes are added to the types.
    #
    def make_type(handle, definition, sub_type: false, &block)
      log "Making JabaType [handle=#{handle}]"

      if @jaba_type_lookup.key?(handle)
        jaba_error("'#{handle}' jaba type multiply defined")
      end

      # Generator is only created if one exists for the type, otherwise it is nil
      #
      generator = nil
      if !sub_type
        generator = make_generator(definition.id)
      end

      jt = JabaType.new(self, definition, handle, generator)

      @jaba_types << jt
      @jaba_type_lookup[handle] = jt

      if sub_type
        if block_given?
          jt.eval_api_block(&block)
        end
      else
        if definition.block
          jt.eval_api_block(&definition.block)
        end
      end

      jt
    end

    ##
    #
    def make_node(type_id: @current_definition.jaba_type_id, name: nil, parent: nil, &block)
      handle = if parent
                 jaba_error('name is required for child nodes') if !name
                 if name.is_a?(JabaNode)
                   name = name.definition_id
                 end
                 "#{parent.handle}|#{name}"
               else
                 jaba_error('name not required for root nodes') if name
                 "#{@current_definition.jaba_type_id}|#{@current_definition.id}"
               end

      log "Making node [type=#{type_id} handle=#{handle}, parent=#{parent}]"

      if @node_lookup.key?(handle)
        jaba_error("Duplicate node handle '#{handle}'")
      end

      jt = get_jaba_type(type_id)

      jn = JabaNode.new(self, @current_definition, jt, handle, parent)

      @nodes << jn
      @node_lookup[handle] = jn
      
      # Give calling block a chance to initialise attributes. This block is in library code as opposed to user
      # definitions so use instance_eval instead of eval_api_block.
      #
      if block_given?
        jn.attrs.instance_eval(&block)
      end
      
      # Next execute defaults block if there is one defined for this type.
      #
      defaults = @current_definition.jaba_type.definition.defaults_definition
      if defaults
        log "  Including defaults"
        jn.eval_api_block(&defaults.block)
      end

      if @current_definition.block
        jn.eval_api_block(&@current_definition.block)
      end
      
      jn.post_create
      jn
    end
    
    ##
    # Given a reference attribute and the definition id it is pointing at, returns the node instance.
    #
    def resolve_reference(ref_attr, ref_node_id)
      ad = ref_attr.attr_def
      make_handle_block = ad.get_property(:make_handle)
      handle = if make_handle_block
        ref_attr.node.eval_api_block(ref_node_id, &make_handle_block)
      else
        "#{ad.referenced_type}|#{ref_node_id}"
      end
      node_from_handle(handle, callstack: ref_attr.last_call_location)
    end

    ##
    #
    def get_null_node(type_id)
      nn = @null_nodes[type_id]
      if !nn
        jt = get_jaba_type(type_id)
        nn = JabaNode.new(self, jt.definition, jt, "Null#{jt.definition_id}", nil)
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
      save_file(input.jaba_input_file, json, :unix, track: false)
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
    def dump_jaba_output
      @output[:generated] = @generated_files
      @output[:warnings] = @warnings
      @generators.each do |g|
        g_root = {}
        @output[g.type_id] = g_root # Namespace each generator
        g.dump_jaba_output(g_root)
      end

      if input.dump_output?
        json = JSON.pretty_generate(@output)
        save_file(input.jaba_output_file, json, :unix, track: false)
      end
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
        jaba_error("'#{id.inspect}' is an invalid flag. Valid flags: #{@jaba_attr_flags.map(&:definition_id)}")
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
    def instanced?(type_id, id)
      get_instance_definition(type_id, id, fail_if_not_found: false) != nil
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
    def node_from_handle(handle, fail_if_not_found: true, callstack: nil)
      n = @node_lookup[handle]
      if !n && fail_if_not_found
        jaba_error("Node with handle '#{handle}' not found", callstack: callstack)
      end
      n
    end
    
    ##
    #
    def jaba_warning(msg, **options)
      log msg, Logger::WARN
      @warnings << make_jaba_error(msg, warn: true, **options).message
    end
    
    ##
    #
    def jaba_error(msg, **options)
      log msg, Logger::ERROR
      raise make_jaba_error(msg, **options)
    end
    
    ##
    #
    def read_file(file, encoding: nil)
      str = nil
      if input.use_file_cache?
        str = @@file_cache[file]
      end
      if str.nil?
        str = IO.read(file, encoding: encoding)
      end
      if input.use_file_cache?
        @@file_cache[file] = str
      end
      str
    end
    
    ##
    #
    def save_file(filename, content, eol, track: true)
      filename = File.expand_path(filename.cleanpath)

      if input.dry_run?
        log "Not saving #{filename} [dry run]"
      else
        log "Saving #{filename}"
      end

      if (eol == :windows) || ((eol == :native) && OS.windows?)
        content = content.gsub("\n", "\r\n")
      end

      # TODO: in case of duplicate check if content matches and fail if it doesn't
      if track
        if @generated_files_lookup.key?(filename)
          jaba_warning "Duplicate file '#{filename}' generated"
        end
        
        # TODO: register generated file for potential use?
        @generated_files_lookup[filename] = nil
        @generated_files << filename
      end
      
      if !input.dry_run?
        dir = File.dirname(filename)
        if !File.exist?(dir)
          FileUtils.makedirs(dir)
        end
        IO.binwrite(filename, content)
      end
    end

    ##
    #
    def glob(spec)
      files = nil
      if input.use_glob_cache?
        files = @@glob_cache[spec]
      end
      if files.nil?
        files = Dir.glob(spec)
        @@glob_cache[spec] = files.sort
      end
      files
    end

    ##
    #
    def execute_definitions(file = nil, &block)
      if file
        log "Executing #{file}"
        @top_level_api.instance_eval(read_file(file), file)
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
    def load_definitions
      # Load core type definitions
      @definition_src_files.concat(glob("#{__dir__}/../definitions/*.rb"))
      
      Array(input.load_paths).each do |p|
        p = p.to_forward_slashes # take copy in case string frozen

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
          files = glob(match)
          if files.empty?
            jaba_warning("No definition files found in #{p}")
          else
            @definition_src_files.concat(files)
          end
        else
          @definition_src_files << p
        end
      end
      
      @definition_src_files.map!(&:cleanpath)

      @definition_src_files.each do |f|
        execute_definitions(f)
      end
    end

    ##
    #
    def init_logger 
      log_file = File.expand_path('jaba.log')
      puts "Logging to #{log_file}..."
      FileUtils.remove(log_file, force: true)
      @logger = Logger.new(log_file)
      @logger.formatter = proc do |severity, datetime, _, msg|
        "#{severity} #{datetime}: #{msg}\n"
      end
      @logger.level = Logger::INFO
      log 'Starting Jaba', section: true
    end

    ##
    #
    def log(msg, severity = Logger::INFO, section: false)
      line = msg
      if section
        n = ((96 - msg.size)/2).round
        line = "#{'=' * n} #{msg} #{'=' * n}"
      end
      @logger&.log(severity, line)
    end

    ##
    # Errors can be raised in 3 contexts:
    #
    # 1) Syntax errors/other ruby errors that are raised by the initial evaluation of the definition files or block in
    #    execute_definitions.
    # 2) From user definitions using the 'fail' API.
    # 3) From core library code. 
    #
    def make_jaba_error(msg, syntax: false, callstack: nil, warn: false)
      msg = msg.capitalize_first if msg.split.first !~ /_/
      
      lines = []
      error_line = nil

      if syntax
        # With ruby ScriptErrors there is no useful callstack. The error location is in the msg itself.
        #
        error_line = msg

        # Delete ruby's way of reporting syntax errors in favour of our own
        #
        msg = msg.sub(/^.* syntax error, /, '')
      else
        cs = Array(callstack || caller)

        # Extract any lines in the callstack that contain references to definition source files.
        #
        lines = cs.select {|c| @definition_src_files.any? {|sf| c.include?(sf)}}
        
        # If no references to definition files assume the error came from internal library code. Raise a RuntimeError.
        #
        if lines.empty?
          e = RuntimeError.new(msg)
          e.set_backtrace(cs)
          return e
        end
        
        # Clean up lines so they only contain file and line information and not the additional ':in ...' that ruby
        # includes. This is not useful in definition errors.
        #
        lines.map! {|l| l.sub(/:in .*/, '')}
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
