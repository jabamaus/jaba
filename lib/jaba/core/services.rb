# frozen_string_literal: true

require_relative 'core_ext'
require_relative 'utils'
require_relative 'jaba_type'
require_relative 'jaba_node'

##
#
module JABA

  using JABACoreExt

  ##
  #
  class Services

    attr_reader :input
    attr_reader :attr_type_api
    attr_reader :attr_definition_api
    attr_reader :jaba_type_api
    attr_reader :jaba_node_api

    ##
    # Records information about each definition the user has made.
    #
    Definition = Struct.new(:type, :id, :block, :options)
    
    ##
    #
    def initialize
      @input = Input.new
      @input.instance_variable_set(:@definitions, nil)
      @input.instance_variable_set(:@load_paths, nil)
      
      @warnings = []
      
      @definition_src_files = []
      
      @all_generated_files = {}
      @added_files = []
      @modified_files = []
      
      @jaba_attr_types = []
      @jaba_types = []
      @jaba_types_to_open = []
      @definition_registry = {} # TODO: not a good name
      
      @file_read_cache = {}
      
      @top_level_api = TopLevelAPI.new
      @attr_type_api = AttributeTypeAPI.new
      @jaba_type_api = JabaTypeAPI.new
      @attr_definition_api = AttributeDefinitionAPI.new
      @jaba_node_api = JabaNodeAPI.new

      @default_attr_type = AttributeType.new(self, nil)
      @default_attr_type.freeze
      
      @top_level_api.__set_obj(self)
    end

    ##
    #
    def define_attr_flag(id)
    end
    
    ##
    #
    def define_attr_type(type, **options, &block)
      @jaba_attr_types << Definition.new(type, nil, block, options)
    end
    
    ##
    #
    def define_type(type, **options, &block)
      @jaba_types << Definition.new(type, nil, block, options)
    end
    
    ##
    #
    def open_type(type, **options, &block)
      @jaba_types_to_open << Definition.new(type, nil, block, options)
    end
    
    ##
    #
    def define_instance(type, id, **options, &block)
      def_data = Definition.new(type, id, block, options)
      
      if id
        if !(id.is_a?(Symbol) || id.is_a?(String)) || id !~ /^[a-zA-Z0-9_.]+$/
          jaba_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
            "(underscore permitted), eg :my_id or 'my_id'")
        end
        if definition_defined?(type, id)
          jaba_error("'#{id}' multiply defined")
        end
      end
      
      @definition_registry.push_value(type, def_data)
    end
    
    ##
    #
    def run
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
      @jaba_attr_types.map! do |def_data|
        at = AttributeType.new(self, def_data.type)
        at.api_eval(&def_data.block)
        at
      end
      
      # Create a JabaType object for each defined type
      #
      @jaba_types.map! do |def_data|
        jt = JabaType.new(self, def_data.type, def_data.options[:extend])
        jt.api_eval(&def_data.block)
        jt
      end
      
      # Open JabaTypes so more attributes can be added
      #
      @jaba_types_to_open.each do |def_data|
        jt = @jaba_types.find {|t| t.type == def_data.type}
        if !jt
          jaba_error("'#{def_data.type}' has not been defined", callstack: def_data.block)
        end
        jt.api_eval(&def_data.block)
      end
      
      @jaba_types.each(&:init)
      
      # Create instances of types
      # TODO: do in dependency order
      #
      @definition_registry.each do |type, defs|
        next if type == :shared
        jt = @jaba_types.find {|t| t.type == type}
        defs.each do |def_data|
          if !jt
            jaba_error("'#{type}' type is not defined. Cannot instance.", callstack: def_data.block)
          end
          nodes = jt.build_nodes(def_data)
          
          # Call generators defined per-type
          #
          jt.generate_hooks.each do |block|
            nodes.each do |n|
              n.instance_eval(&block) # TODO: which api?
            end
          end
          
          # Call generators defined per-node
          #
          nodes.each do |n|
            n.generate_hooks.each do |gh|
              n.instance_eval(&gh) # TODO: which api?
            end
          end
        end
      end
      
      op = Output.new
      op.instance_variable_set(:@added_files, @added_files)
      op.instance_variable_set(:@modified_files, @modified_files)
      op.instance_variable_set(:@warnings, @warnings)
      op
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
    def get_jaba_type(type, fail_if_not_found: true)
      jt = @jaba_types.find{|t| t.type == type}
      if !jt && fail_if_not_found
        jaba_error("'#{type}' type not defined")
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
    def jaba_warning(msg, **options)
      @warnings << make_jaba_error(msg, warn: true, **options).message
    end
    
    ##
    #
    def jaba_error(msg, **options)
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
    # TODO: keep a cache of checksums
    def write_file(fn, str)
      exists = File.exist?(fn)
      existing_str = exists ? IO.binread(fn).force_encoding(str.encoding) : nil
      equal = (exists && (str == existing_str))
      
      if !equal
        dir = File.dirname(fn)
        if !File.exist?(dir)
          FileUtils.makedirs(dir)
        end
        File.open(fn, 'wb') do |f|
          f.write(str)
        end
      end
      
      if !exists
        :added
      elsif !equal
        :modified
      end
    end
    
    ##
    #
    def save_file(filename, content, eol)
      if (eol == :windows) || ((eol == :native) && OS.windows?)
        content = content.gsub("\n", "\r\n")
      end
      # filename = filename.cleanpath
      # log "Saving #{filename}"
      warning "Duplicate file '#{filename}' generated" if @all_generated_files.key?(filename)
      
      # register_src_file(filename)
      @all_generated_files[filename] = nil
      
      case write_file(filename, content)
      when :modified
        @modified_files << filename
      when :added
        @added_files << filename
      end
    end

    private
    
    ##
    #
    def execute_definitions(file = nil, &block)
      if file
        @top_level_api.instance_eval(IO.read(file), file)
      end
      if block_given?
        @definition_src_files << block.source_location[0]
        @top_level_api.instance_eval(&block)
      end
    rescue JabaError
      raise # Prevent fallthrough to next case
    rescue Exception => e # Catch all errors, including SyntaxErrors, by rescuing Exception
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
          @definition_src_files.concat(Dir.glob("#{p}/*.rb"))
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
      
      cs = if callstack
             if callstack.is_a?(Proc)
               callstack.source_location.join(':')
             else
               callstack
             end
           else
             caller
           end
      
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
