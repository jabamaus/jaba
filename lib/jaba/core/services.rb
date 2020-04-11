# frozen_string_literal: true

require 'fileutils'
require 'logger'
require_relative 'core_ext'
require_relative 'utils'
require_relative 'definition_common'
require_relative 'jaba_type'
require_relative 'attribute_definition'
require_relative 'attribute'
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
    AttrTypeInfo = Struct.new(:type, :block, :api_call_line)
    JabaTypeInfo = Struct.new(:type, :block, :options, :api_call_line)
    JabaInstanceInfo = Struct.new(:type, :id, :block, :options, :api_call_line)
    
    ##
    #
    def initialize
      @input = Input.new
      @input.instance_variable_set(:@definitions, nil)
      @input.instance_variable_set(:@load_paths, nil)
      @input.instance_variable_set(:@enable_logging, false)
      
      @logger = nil
      
      @warnings = []
      
      @definition_src_files = []
      
      @generated_files_hash = {}
      @generated_files = []
      
      @jaba_attr_types = []
      @jaba_types = []
      @jaba_types_to_open = []
      @definition_registry = {}
      @jaba_types_to_instance = []
      @nodes = []
      @node_lookup = {}
      
      @file_read_cache = {}
      
      @top_level_api = TopLevelAPI.new(self)

      @default_attr_type = AttributeTypeDefinition.new(self, AttrTypeInfo.new).freeze
    end

    ##
    # This is absolutely CRITICAL if running jaba with ruby-debug-ide.
    #
    def inspect
      nil
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
    def define_attr_flag(id)
    end
    
    ##
    #
    def define_attr_type(type, &block)
      @jaba_attr_types << AttrTypeInfo.new(type, block, caller(2, 1)[0])
    end
    
    ##
    #
    def define_type(type, **options, &block)
      @jaba_types << JabaTypeInfo.new(type, block, options, caller(2, 1)[0])
    end
    
    ##
    #
    def open_type(type, &block)
      @jaba_types_to_open << JabaTypeInfo.new(type, block, nil, caller(2, 1)[0])
    end
    
    ##
    #
    def define_instance(type, id, **options, &block)
      log "Instancing #{type} [id=#{id}]"
      
      if id
        if !(id.is_a?(Symbol) || id.is_a?(String)) || id !~ /^[a-zA-Z0-9_.]+$/
          jaba_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
            "(underscore permitted), eg :my_id or 'my_id'")
        end
        if definition_defined?(type, id)
          jaba_error("'#{id}' multiply defined")
        end
      end
      
      info = JabaInstanceInfo.new(type, id, block, options, caller(2, 1)[0])
      @definition_registry.push_value(type, info)
      
      if type != :shared
        @jaba_types_to_instance << info
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
      @jaba_attr_types.map! {|info| AttributeTypeDefinition.new(self, info)}
      
      # Create a JabaType object for each defined type
      #
      @jaba_types.map! {|info| JabaTypeDefinition.new(self, info)}
      
      # Open JabaTypes so more attributes can be added
      #
      @jaba_types_to_open.each do |info|
        get_jaba_type(info.type).eval_definition(&info.block) # TODO: use api_call_line
      end
      
      @jaba_types.each(&:init)
      @jaba_types.each(&:resolve_dependencies)
      
      begin
        @jaba_types.sort_topological!(:dependencies)
      rescue CyclicDependency => e
        err_type = e.instance_variable_get(:@err_obj)
        jaba_error("'#{err_type}' contains a cyclic dependency") # TODO: error location
      end
      
      @jaba_types.each_with_index {|jt, i| jt.instance_variable_set(:@order_index, i)}
      
      @jaba_types_to_instance.each do |info|
        info.type = get_jaba_type(info.type, callstack: info.api_call_line)
      end
      
      @jaba_types_to_instance.stable_sort_by! {|d| d.type.instance_variable_get(:@order_index)}
      
      # Create instances of types
      #
      @jaba_types_to_instance.each do |info|
        @current_info = info
        if info.type.generator
          info.type.generator.make_nodes
        else
          make_node
        end
      end
      
      # Resolve references
      #
      @nodes.each do |n|
        n.each_attr do |a|
          if a.type == :reference
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
      
      @jaba_types.each {|jt| jt.generator&.generate}

      # Call generators defined per-node
      #
      @nodes.each do |n|
        n.generate_hooks.each do |gh|
          n.instance_eval(&gh)
        end
      end

      @logger&.close
      
      op = Output.new
      op.instance_variable_set(:@generated_files, @generated_files)
      op.instance_variable_set(:@warnings, @warnings)
      op
    end
    
    ##
    #
    def make_node(type: nil, handle: "#{@current_info.type}|#{@current_info.id}", attrs: nil, parent: nil, &block)
      type = type ? get_jaba_type(type) : @current_info.type
      jn = JabaNode.new(self, type, @current_info.id, @current_info.api_call_line, handle, attrs, parent)
      @nodes << jn
      
      # A node only needs a handle if it will be looked up.
      #
      if handle
        if @node_lookup.key?(handle)
          jaba_error("Duplicate node handle '#{handle}'")
        end
        @node_lookup[handle] = jn
      end
      
      jn.eval_definition(context: :internal, &block) if block_given?
      jn.eval_definition(&@current_info.block)
      jn.post_create
      jn
    end
    
    ##
    #
    def get_attribute_type(type)
      if type.nil?
        return @default_attr_type
      end
      t = @jaba_attr_types.find {|at| at.type == type}
      if !t
        jaba_error("'#{type}' attribute type is undefined. Valid types: #{@jaba_attr_types.map(&:type)}")
      end
      t
    end
    
    ##
    #
    def get_jaba_type(type, fail_if_not_found: true, callstack: nil)
      jt = @jaba_types.find {|t| t.type == type}
      if !jt && fail_if_not_found
        jaba_error("'#{type}' type not defined", callstack: callstack)
      end
      jt
    end
    
    ##
    #
    def get_definition(type, id, fail_if_not_found: true)
      defs = @definition_registry[type]
      return nil if !defs
      d = defs.find {|dd| dd.id == id}
      if !d && fail_if_not_found
        jaba_error("No '#{id}' definition found")
      end
      d
    end

    ##
    #
    def definition_defined?(type, id)
      get_definition(type, id, fail_if_not_found: false) != nil
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
      cached = @file_read_cache[file]
      return cached if cached
      content = IO.read(file, encoding: encoding)
      @file_read_cache[file] = content
      content
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

    private
    
    ##
    #
    def execute_definitions(file = nil, &block)
      if file
        log "Executing #{file}"
        @top_level_api.instance_eval(IO.read(file), file)
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
      @definition_src_files << "#{__dir__}/types.rb" # Load core type definitions
      Array(input.load_paths).each do |p|
        if !File.exist?(p)
          jaba_error("#{p} does not exist")
        end
        if File.directory?(p)
          @definition_src_files.concat(Dir.glob("#{p}/**/jaba.rb"))
        else
          @definition_src_files << p
        end
      end
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
