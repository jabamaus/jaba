require_relative 'Utils'
require_relative 'JabaType'
require_relative 'JabaObject'

module JABA

class Services

  attr_reader :input
  attr_reader :attr_definition_api
  attr_reader :jaba_attr_types
  attr_reader :jaba_object_api

  ##
  # Records information about each definition the user has made.
  #
  Definition = Struct.new(:type, :id, :block, :options)
  
  ##
  #
  def initialize
    @input = Input.new
    @input.instance_variable_set(:@definitions, nil)
    @input.root = Dir.getwd
    
    @info = []
    @warnings = []
    
    @definition_src_files = []
    
    @all_generated_files = {}
    @added_files = []
    @modified_files = []
    
    @jaba_attr_types = []
    @jaba_types = []
    @types_to_extend = []
    @definition_registry = {} # TODO: not a good name
    
    @file_read_cache = {}
    
    @toplevel_api = TopLevelAPI.new
    @attr_type_api = AttributeTypeAPI.new
    @jaba_type_api = JabaTypeAPI.new
    @attr_definition_api = AttributeDefinitionAPI.new
    @jaba_object_api = JabaObjectAPI.new

    @toplevel_api.__internal_set_obj(self)
  end

  ##
  #
  def run
    Dir.chdir(input.root) do
      return execute
    end
  end
  
  ##
  #
  def info(msg)
    @info << msg
  end
  
  ##
  #
  def warning(msg)
    @warnings << msg
  end
  
  ##
  #
  def define_attr_type(type, **options, &block)
    @jaba_attr_types << Definition.new(type, nil, block, options)
  end
  
  ##
  #
  def get_attribute_type(type, fail_if_not_found: true)
    @jaba_attr_types.find{|at| at.type == type}
  end
  
  ##
  #
  def define_attr_flag(id)
  end
  
  ##
  #
  def define_type(type, **options, &block)
    @jaba_types << Definition.new(type, nil, block, options)
  end
  
  ##
  #
  def extend_type(type, **options, &block)
    @types_to_extend << Definition.new(type, nil, block, options)
  end
  
  ##
  #
  def define_instance(type, id, **options, &block)
    def_data = Definition.new(type, id, block, options)
    
    if id
      if (!(id.is_a?(Symbol) or id.is_a?(String)) or id !~ /^[a-zA-Z0-9_.]+$/)
        jaba_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'")
      end
      if definition_defined?(type, id)
        jaba_error("'#{id}' multiply defined")
      end
    end
    
    @definition_registry.push_value(type, def_data)
  end
  
  ##
  #
  def get_definition(type, id, fail_if_not_found: true)
    defs = @definition_registry[type]
    return nil if !defs
    d = defs.find{|dd| dd.id == id}
    raise "No '#{id}' definition found" if (!d and fail_if_not_found)
    d
  end

  ##
  #
  def definition_defined?(type, id)
    get_definition(type, id, fail_if_not_found: false) != nil
  end
  
  ##
  #
  def jaba_warning(msg, callstack: nil)
    warning make_jaba_error(msg, callstack: callstack, warn: true).message
  end
  
  ##
  #
  def jaba_error(msg, callstack: nil)
    raise make_jaba_error(msg, callstack: callstack)
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
  def write_file(fn, str)
    equal = false
    exists = File.exist?(fn)
    existing_str = exists ? IO.binread(fn).force_encoding(str.encoding) : nil
    equal = (exists and str == existing_str)
    
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
    if (eol == :windows or (eol == :native and OS.windows?))
      content.gsub!("\n", "\r\n")
    end
    #filename = filename.cleanpath
    #log "Saving #{filename}"
    warning "Duplicate file '#{filename}' generated" if @all_generated_files.has_key?(filename)
    
    #register_src_file(filename)
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
  def execute
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
      @attr_type_api.__internal_set_obj(at)
      @attr_type_api.instance_eval(&def_data.block)
      at
    end
    
    # Create a JabaType object for each defined type
    #
    @jaba_types.map! do |def_data|
      jt = JabaType.new(self, def_data.type)
      @jaba_type_api.__internal_set_obj(jt)
      @jaba_type_api.instance_eval(&def_data.block)
      jt
    end
    
    # Extend JabaTypes
    #
    @types_to_extend.each do |def_data|
      jt = @jaba_types.find{|t| t.type == def_data.type}
      if !jt
        jaba_error("'#{def_data.type}' has not been defined", callstack: def_data.block)
      end
      @jaba_type_api.__internal_set_obj(jt)
      @jaba_type_api.instance_eval(&def_data.block)
    end
    
    @jaba_types.each(&:init)
    
    # Create instances of types
    # TODO: do generically and in dependency order
    #
    create_instances(:text)
    create_instances(:target)
    create_instances(:category)
    create_instances(:project)
    create_instances(:workspace)
    
    op = Output.new
    op.instance_variable_set(:@added_files, @added_files)
    op.instance_variable_set(:@modified_files, @modified_files)
    op.instance_variable_set(:@warnings, @warnings)
    op
  end
  
  ##
  #
  def create_instances(type)
    defs = @definition_registry[type]
    if defs
      defs.each do |def_data|
        jt = @jaba_types.find{|t| t.type == def_data.type}
        jo = JabaObject.new(self, jt, def_data.id)
        @jaba_object_api.__internal_set_obj(jo)
        @jaba_object_api.instance_eval(&def_data.block)
        jo.call_generators
      end
    end
  end
  
  ##
  #
  def execute_definitions(file=nil, &block)
    if file
      @toplevel_api.instance_eval(read_file(file), file)
    end
    if block_given?
      @definition_src_files << block.source_location[0]
      @toplevel_api.instance_eval(&block)
    end
  rescue JabaError
    raise # Prevent fallthrough to next case
  rescue Exception => e # Catch all errors, including SyntaxErrors, by rescuing Exception
    raise make_jaba_error("#{e.class}: #{e.message}", callstack: e.backtrace)
  end
  
  ##
  #
  def load_definitions
    @definition_src_files << "#{__dir__}/Types.rb" # Load core type definitions
    Array(input.load_paths).each do |p|
      raise "#{p} does not exist" if !File.exist?(p)
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
  # Errors can be raised in 3 contexts:
  #
  # 1) Syntax errors/other ruby errors that are raised by the initial evaluation of the definition files or block in execute_definitions.
  #    In this case no definition information will have been loaded. In this case the callstack is passed in and will be the backtrace of the
  #    ruby exception.
  # 2) Errors that are raised explicitly in the definitions themselves, or from in core code that is called directly from the definitions.
  #    In this context the relevant definition lines will be in the callstack when the error was raised. In this case no callstack needs
  #    to be passed in and the relevant callstack will be automatically extracted from the current callstack by extracting all lines that
  #    contain a reference to any definition source file.
  # 3) Finally, errors can be raised from core code that are not in the context of definition execution - eg after they have finished
  #    executing in a validation phase. In this case there will be no definition-level callstack and the closest possible source file location
  #    must be passed in.
  #
  # If the callstack is passed in it can either take the format of a normal ruby callstack as returned by Exception#backtrace or by 'caller' method,
  # or it can be a block (indicating that the error occurred somewhere in that block of code). In the case of a block the blocks source code location
  # is used and the callstack will only have one item. A block will be passed when the error is raised from outside the context of definition execution
  # - see case 3 above.
  #
  def make_jaba_error(msg, callstack: nil, warn: false)
    if callstack
      if callstack.is_a?(Proc)
        cs = callstack.source_location.join(':')
      else
        cs = callstack
      end
    else
      cs = caller
    end
    
    # Extract any lines in the callstack that contain references to definition source files.
    #
    lines = Array(cs).select{|c| @definition_src_files.any?{|sf| c.include?(sf)}}
    raise 'Callstack must not be empty' if lines.empty?
    
    # Clean up lines so they only contain file and line information and not the additional ':in ...' that ruby includes. This is not useful
    # in definition errors.
    #
    lines.map!{|l| l.sub(/:in .*/, '')}

    # Extract file and line information from the first callstack item, which is where the main error occurred.
    #
    if lines[0] !~ /^(.+):(\d+)/
      raise "Could not extract file and line number from '#{lines[0]}'"
    end
    
    file = $1
    line = $2.to_i
    
    m = ''
    m << (warn ? 'Warning' : 'Error')
    m << (callstack.is_a?(Proc) ? ' near' : ' at')
    m << " #{file.basename}:#{line}:"
    m << " #{msg.capitalize_first}"
    
    e = JabaError.new(m)
    e.instance_variable_set(:@file, file)
    e.instance_variable_set(:@line, line)
    e.set_backtrace(lines)
    e
  end

end

end
