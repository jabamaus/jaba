require_relative 'Utils'
require_relative 'JabaType'
require_relative 'JabaObject'

module JABA

class Services

  attr_reader :input
  
  ##
  # Records information about each definition the user has made.
  #
  Definition = Struct.new(:type, :id, :block, :options)
  
  attr_reader :attr_definition_api
  attr_reader :jaba_attr_types
  
  ##
  #
  def initialize
    @input = Input.new
    @input.instance_variable_set(:@definitions, nil)
    @input.root = Dir.getwd
    
    @info = []
    @warnings = []
    
    @added_files = []
    @modified_file = []
    
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
        definition_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'", block.source_location)
      end
      if definition_defined?(type, id)
        definition_error("'#{id}' multiply defined", block.source_location)
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
  def definition_warning(msg, source_location, backtrace: nil)
    warning make_definition_error(msg, source_location, backtrace: backtrace, warn: true).message
  end
  
  ##
  #
  def definition_error(msg, source_location, backtrace: nil)
    raise make_definition_error(msg, source_location, backtrace: backtrace)
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
        definition_error("'#{def_data.type}' has not been defined", def_data.block.source_location)
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
        jo = JabaObject.new(jt, def_data.id, def_data.block.source_location)
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
      @toplevel_api.instance_eval(&block)
    end
  rescue DefinitionError
    raise # Prevent fallthrough to next case
  rescue Exception => e # Catch all errors, including SyntaxErrors, by rescuing Exception
    raise make_definition_error("#{e.class}: #{e.message}", e.backtrace[0])
  end
  
  ##
  #
  def load_definitions
    files = []
    files << "#{__dir__}/Types.rb" # Load core type definitions
    Array(input.load_paths).each do |p|
      raise "#{p} does not exist" if !File.exist?(p)
      if File.directory?(p)
        files.concat(Dir.glob("#{p}/*.rb"))
      else
        files << p
      end
    end
    files.each do |f|
      execute_definitions(f)
    end
  end

  ##
  #
  def make_definition_error(msg, source_location, backtrace: nil, warn: false)
    m = ''
    file = nil
    line = nil
    
    if source_location
      if source_location.is_a?(Array)
        file = source_location[0]
        line = source_location[1]
      else
        if source_location !~ /^(.+):(\d+):/
          raise "Could not determine file and line number from source location '#{source_location}'"
        end
        file = $1
        line = $2.to_i
      end
      m << (warn ? 'Warning' : 'Error')
      m << " at #{file.basename}:#{line}:"
      m << " #{msg.capitalize_first}"
    else
      m << msg
    end
    
    e = DefinitionError.new(m)
    
    if source_location
      e.instance_variable_set(:@file, file)
      e.instance_variable_set(:@line, line)
      if backtrace
        backtrace = backtrace.map{|elem| Array(elem).join(':')}
        e.set_backtrace(backtrace)
      else
        e.set_backtrace([])
      end
    end
    e
  end

end

end
