# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'json'
require_relative 'core_ext'
require_relative 'utils'
require_relative 'jaba_object'
require_relative 'jaba_attribute_type'
require_relative 'jaba_attribute_flag'
require_relative 'jaba_attribute_definition'
require_relative 'jaba_attribute'
require_relative 'jaba_type'
require_relative 'jaba_node'
require_relative 'project'
require_relative 'generator'

Dir.glob("#{__dir__}/../generators/*_generator.rb").sort.each {|f| require f}

##
#
module JABA

  using JABACoreExt

  ##
  #
  class Services

    attr_reader :input

    ##
    # Records information about each definition the user has made.
    #
    AttrTypeInfo = Struct.new(:type_id, :block, :api_call_line)
    AttrFlagInfo = Struct.new(:id, :block, :api_call_line)
    JabaTypeInfo = Struct.new(:type_id, :block, :options, :api_call_line)
    JabaInstanceInfo = Struct.new(:type_id, :jaba_type, :id, :block, :options, :api_call_line)
    DefaultsInfo = Struct.new(:type_id, :block, :api_call_line)

    @@file_cache = {}
    @@glob_cache = {}

    ##
    #
    def initialize
      @input = Input.new
      @input.instance_variable_set(:@definitions, nil)
      @input.instance_variable_set(:@load_paths, Dir.getwd)
      @input.instance_variable_set(:@enable_logging, false)
      @input.instance_variable_set(:@use_file_cache, false)
      @input.instance_variable_set(:@use_glob_cache, false)
      
      @logger = nil
      
      @warnings = []
      
      @definition_src_files = []
      
      @generated_files_hash = {}
      @generated_files = []
      
      @jaba_type_infos = []

      @jaba_attr_types = []
      @jaba_attr_flags = []
      @jaba_types = []
      @additional_jaba_types = []
      @jaba_types_to_open = []
      @instances = []
      @defaults = []

      @jaba_type_lookup = {}
      @instance_lookup = {}

      @generators = []

      @nodes = []
      @node_lookup = {}
      @root_nodes = []
      
      @top_level_api = TopLevelAPI.new(self)

      @default_attr_type = JabaAttributeType.new(self, AttrTypeInfo.new).freeze
    end

    ##
    #
    def log(msg, severity = Logger::INFO)
      @logger&.log(severity, msg)
    end

    ##
    #
    def log_debug(msg)
      @logger&.debug(msg)
    end
    
    ##
    #
    def define_attr_type(type_id, &block)
      jaba_error("type_id is required") if type_id.nil?
      validate_id(type_id)
      # TODO: check for dupes
      @jaba_attr_types << AttrTypeInfo.new(type_id, block, caller(2, 1)[0])
    end

    ##
    #
    def define_attr_flag(id, &block)
      jaba_error("id is required") if id.nil?
      validate_id(id)
      # TODO: check for dupes
      @jaba_attr_flags << AttrFlagInfo.new(id, block, caller(2, 1)[0])
    end

    ##
    #
    def define_type(type_id, **options, &block)
      jaba_error("type_id is required") if type_id.nil?
      validate_id(type_id)
      # TODO: check for dupes
      @jaba_type_infos << JabaTypeInfo.new(type_id, block, options, caller(2, 1)[0])
    end
    
    ##
    #
    def open_type(type_id, &block)
      jaba_error("type_id is required") if type_id.nil?
      jaba_error("a block is required") if !block_given?
      @jaba_types_to_open << JabaTypeInfo.new(type_id, block, nil, caller(2, 1)[0])
    end
    
    ##
    #
    def define_instance(type_id, id, **options, &block)
      jaba_error("type_id is required") if type_id.nil?
      jaba_error("id is required") if id.nil?

      validate_id(id)

      log "Instancing #{type_id} [id=#{id}]"

      if instanced?(type_id, id)
        jaba_error("'#{id}' multiply defined")
      end
      
      info = JabaInstanceInfo.new(type_id, nil, id, block, options, caller(2, 1)[0])
      @instance_lookup.push_value(type_id, info)
      
      if type_id == :shared
        jaba_error("a block is required") if !block_given?
      else
        @instances << info
      end
    end
    
    ##
    #
    def define_defaults(type_id, &block)
      jaba_error("type_id is required") if type_id.nil?
      existing = @defaults.find {|info| info.type_id == type_id}
      if existing
        jaba_error("'#{type_id}' defaults multiply defined")
      end
      @defaults << DefaultsInfo.new(type_id, block, caller(2, 1)[0])
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
        FileUtils.remove('jaba.log', force: true)
        @logger = Logger.new('jaba.log')
        @logger.formatter = proc do |severity, datetime, _, msg|
          "#{severity} #{datetime}: #{msg}\n"
        end
        @logger.level = Logger::INFO
        log '===== Starting Jaba ====='
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
      @jaba_attr_types.map! {|info| JabaAttributeType.new(self, info)}
      
      # Create attribute flags
      #
      @jaba_attr_flags.map! {|info| JabaAttributeFlag.new(self, info)}

      # Create JabaTypes and Generators
      #
      @jaba_type_infos.each do |info|
        type_id = info.type_id
        generator = make_generator(type_id)

        # JabaTypes can have some of their attributes split of into separate JabaTypes to help with node
        # creation in the case where a tree of nodes is created from a single definition. These JabaTypes
        # are created on the fly as attributes are added to the types.
        #
        jt = JabaType.new(self, type_id, info.block, get_defaults_block(type_id), generator)
        @jaba_types << jt
      end

      # Init JabaTypes. This can cause additional JabaTypes to be created
      #
      @jaba_types.each(&:init)
      @jaba_types.concat(@additional_jaba_types)
      @jaba_types.each(&:init_attrs)
      
      # Open JabaTypes so more attributes can be added
      #
      @jaba_types_to_open.each do |info|
        get_jaba_type(info.type_id).eval_api_block(&info.block)
      end
      
      @jaba_types.each(&:resolve_dependencies)
      
      begin
        @jaba_types.sort_topological!(:dependencies)
      rescue CyclicDependency => e
        err_type = e.instance_variable_get(:@err_obj)
        jaba_error("'#{err_type}' contains a cyclic dependency")
      end
      
      @jaba_types.each_with_index {|jt, i| jt.instance_variable_set(:@order_index, i)}
      
      @instances.each do |info|
        info.jaba_type = get_jaba_type(info.type_id, callstack: info.api_call_line)
      end
      
      @instances.stable_sort_by! {|d| d.jaba_type.instance_variable_get(:@order_index)}
      
      # Create instances of types
      #
      @instances.each do |info|
        @current_info = info
        g = info.jaba_type.generator
        if g
          g.instance_variable_set(:@definition_id, info.id)
          @root_nodes << g.make_nodes
        else
          @root_nodes << make_node
        end
      end
      
      # Resolve references
      #
      @nodes.each do |n|
        n.each_attr do |a|
          if a.type_id == :reference
            a.map! do |ref|
              if ref.is_a?(Symbol)
                node_from_handle("#{a.attr_def.get_property(:referenced_type)}|#{ref}")
              else
                ref
              end
            end
          end
        end
      end
      
      # Output definition input data as a json file, before generation. This is raw data as generated from the definitions.
      # Can be used for debugging and testing.
      #
      doc = {}
      nodes_root = {}
      doc[:nodes] = nodes_root
      @root_nodes.each do |rn|
        obj = {}
        nodes_root[rn.handle] = obj
        write_node_json(rn, obj)
      end

      json = JSON::pretty_generate(doc)
      save_file('jaba.input.json', json, :unix)

      # Call generators
      #
      @generators.each(&:generate)

      # Call generators defined per-node, in the context of the node itself, not its api
      #
      @nodes.each do |n|
        n.generate_hooks.each do |gh|
          n.instance_eval(&gh)
        end
      end

      @logger&.close
      
      puts @warnings
      
      op = Output.new
      op.instance_variable_set(:@generated_files, @generated_files)
      op.instance_variable_set(:@warnings, @warnings)
      op
    end
    
    ##
    #
    def make_generator(type_id)
      g = nil
      gen_classname = "JABA::#{type_id.to_s.capitalize_first}Generator"
      
      if Object.const_defined?(gen_classname)
        generator_class = Module.const_get(gen_classname)

        if generator_class.superclass != Generator
          raise "#{generator_class} must inherit from Generator class"
        end

        log "Creating #{generator_class}"

        g = generator_class.new(self)
        g.init

        @generators << g
      end
      g
    end

    ##
    #
    def make_node(type_id: @current_info.type_id, 
                  id: @current_info.id,
                  handle: "#{@current_info.type_id}|#{@current_info.id}",
                  parent: nil,
                  &block)
      
      validate_id(id)

      jt = get_jaba_type(type_id)

      jn = JabaNode.new(self, jt, @current_info.id, id, @current_info.api_call_line, handle, parent)
      @nodes << jn
      
      # A node only needs a handle if it will be looked up.
      #
      if handle
        if @node_lookup.key?(handle)
          jaba_error("Duplicate node handle '#{handle}'")
        end
        @node_lookup[handle] = jn
      end
      
      # Give calling block a chance to initialise attributes. This block is in library code as opposed to user
      # definitions so use instance_eval instead of eval_api_block.
      #
      if block_given?
        jn.attrs.instance_eval(&block)
      end
      
      # Next execute defaults block if there is one defined for this type
      #
      defaults = jn.jaba_type.defaults_block
      if defaults
        jn.eval_api_block(&defaults)
      end

      if @current_info.block
        jn.eval_api_block(&@current_info.block)
      end
      
      jn.post_create
      jn
    end
    
    ##
    #
    def write_node_json(node, obj)
      node.each_attr do |attr|
        obj[attr.id] = attr.get
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
    def register_additional_jaba_type(jt)
      @additional_jaba_types << jt
    end

    ##
    #
    def register_jaba_type_lookup(jt, type_id)
      if @jaba_type_lookup.has_key?(type_id)
        jaba_error("'#{type_id}' jaba type multiply defined")
      end
      @jaba_type_lookup[type_id] = jt
    end

    ##
    #
    def get_attribute_type(type_id)
      if type_id.nil?
        return @default_attr_type
      end
      t = @jaba_attr_types.find {|at| at.type_id == type_id}
      if !t
        jaba_error("'#{type_id}' attribute type is undefined. Valid types: #{@jaba_attr_types.map(&:type_id)}")
      end
      t
    end
    
    ##
    #
    def get_jaba_type(type_id, fail_if_not_found: true, callstack: nil)
      jt = @jaba_type_lookup[type_id]
      if !jt && fail_if_not_found
        jaba_error("'#{type_id}' type not defined", callstack: callstack)
      end
      jt
    end
    
    ##
    #
    def get_instance_info(type_id, id, fail_if_not_found: true)
      defs = @instance_lookup[type_id]
      return nil if !defs
      d = defs.find {|dd| dd.id == id}
      if !d && fail_if_not_found
        jaba_error("No '#{id}' definition found")
      end
      d
    end

    ##
    #
    def instanced?(type_id, id)
      get_instance_info(type_id, id, fail_if_not_found: false) != nil
    end
    
    ##
    #
    def get_defaults_block(type_id)
      d = @defaults.find {|info| info.type_id == type_id}
      if d
        d.block
      else
        nil
      end
    end

    ##
    #
    def node_from_handle(handle, fail_if_not_found: true)
      n = @node_lookup[handle]
      if !n && fail_if_not_found
        jaba_error("Node with handle '#{handle}' not found")
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
    def save_file(filename, content, eol)
      if (eol == :windows) || ((eol == :native) && OS.windows?)
        content = content.gsub("\n", "\r\n")
      end
      filename = filename.cleanpath
      log "Saving #{filename}"
      jaba_warning "Duplicate file '#{filename}' generated" if @generated_files_hash.key?(filename)
      
      # register_src_file(filename)
      @generated_files_hash[filename] = nil
      @generated_files << filename
      
      dir = File.dirname(filename)
      if !File.exist?(dir)
        FileUtils.makedirs(dir)
      end
      File.open(filename, 'wb') do |f|
        f.write(content)
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

    private
    
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
    rescue JabaError
      raise # Prevent fallthrough to next case
    rescue StandardError, ScriptError => e # Catches syntax errors
      jaba_error(e.message, syntax: true, callstack: e.backtrace)
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
    # Errors can be raised in 4 contexts:
    #
    # 1) Syntax errors/other ruby errors that are raised by the initial evaluation of the definition files or block in
    #    execute_definitions. In this case no definition information will have been loaded. In this case the callstack
    #    is passed in and will be the backtrace of the ruby exception.
    # 2) Errors that are raised explicitly in the definitions themselves, or from in core code that is called directly
    #    from the definitions. In this context the relevant definition lines will be in the callstack when the error was
    #    raised. In this case no callstack needs to be passed in and the relevant callstack will be automatically
    #    extracted from the current callstack by extracting all lines that contain a reference to any definition source
    #    file.
    # 3) Errors can be raised from core code that are about user definitions but are not in their context - eg after
    #    they have finished executing in a validation phase. In this case there will be no definition-level callstack
    #    and the closest possible source file location must be passed in.
    # 4) Errors can be raised internally from core code. In this case the internal? method on the JabaError exception
    #    will be true.
    #
    # If the callstack is passed in it can either take the format of a normal ruby callstack as returned by
    # Exception#backtrace or by 'caller' method, or it can be a block (indicating that the error occurred somewhere in
    # that block of code). In the case of a block the blocks source code location is used and the callstack will only
    # have one item. A block will be passed when the error is raised from outside the context of definition execution
    # - see case 3 above.
    #
    def make_jaba_error(msg, syntax: false, callstack: nil, warn: false)
      msg = msg.capitalize_first
      
      cs = callstack || caller
      
      # Extract any lines in the callstack that contain references to definition source files.
      #
      lines = Array(cs).select {|c| @definition_src_files.any? {|sf| c.include?(sf)}}
      
      # TODO: include DefinitionAPI.rb/ExtensionAPI.rb info in syntax errors
      
      # If no references to definition files assume the error came from internal library code. Do no further processing
      # so the exception will have the normal ruby backtrace.
      #
      if lines.empty?
        e = JabaError.new(msg)
        e.instance_variable_set(:@internal, true)
        return e
      end
      
      # Clean up lines so they only contain file and line information and not the additional ':in ...' that ruby
      # includes. This is not useful in definition errors.
      #
      lines.map! {|l| l.sub(/:in .*/, '')}

      # Extract file and line information from the first callstack item, which is where the main error occurred.
      #
      if lines[0] !~ /^(.+):(\d+)/
        raise "Could not extract file and line number from '#{lines[0]}'"
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
      
      m << (callstack.is_a?(Proc) ? ' near' : ' at')
      m << " #{file.basename}:#{line}"
      m << ": #{msg}"
      
      e = JabaError.new(m)
      e.instance_variable_set(:@raw_message, msg)
      e.instance_variable_set(:@internal, false)
      e.instance_variable_set(:@file, file)
      e.instance_variable_set(:@line, line)
      e.set_backtrace(lines)
      e
    end

  end

end
