require_relative 'Utils'
require_relative 'JabaType'

module JABA

class Services

  attr_reader :input
  
  ##
  # Records information about each definition the user has made.
  #
  Definition = Struct.new(:type, :id, :file, :line, :block, :options)
  
  attr_reader :attr_definition_api
  
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
    
    @definition_type_registry = {}
    @jaba_type_registry = {}
    @definition_registry = {}
    
    @file_read_cache = {}
    
    @next_flag = 1 << 0
    @toplevel_definition_api = TopLevelDefinitionAPI.new
    @type_extension_api = DefinitionTypeExtensionAPI.new
    @attr_definition_api = AttributeDefinitionAPI.new

    @toplevel_definition_api.__internal_set_obj(self)
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
  def register_attr_flag(id)
    JABA.const_set(id, @next_flag)
    @next_flag <<= 1
  end
  
  ##
  #
  def extend_type(type, **options, &block)
    if caller[1] !~ /^(.*)?:(\d+):/
      raise "Could not determine file and line number for '#{type}'"
    end
    
    file = $1
    line = $2.to_i
    
    def_data = Definition.new(type, nil, file, line, block, options)
    @definition_type_registry.push_value(type, def_data)
  end
  
  ##
  # type can be eg :project, :workspace, :target, :shared, :attr, :attr_type etc.
  #
  def register_definition(type, id, **options, &block)
    if caller[1] !~ /^(.*)?:(\d+):/
      raise "Could not determine file and line number for '#{type}' '#{id}'"
    end
    
    file = $1
    line = $2.to_i
    
    def_data = Definition.new(type, id, file, line, block, options)
    @current_definition = def_data
    
    if id
      if (!(id.is_a?(Symbol) or id.is_a?(String)) or id !~ /^[a-zA-Z0-9_.]+$/)
        definition_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'")
      end
      if definition_defined?(type, id)
        definition_error("'#{id}' multiply defined")
      end
    end
    
    @definition_registry.push_value(type, def_data)
    @current_definition = nil
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
  def definition_warning(msg)
    warning make_definition_error(msg, warn: true).message
  end
  
  ##
  #
  def definition_error(msg)
    raise make_definition_error(msg)
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
    
    @definition_type_registry.each do |type_id, defs|
      defs.each do |d|
        @current_definition = d
        jt = @jaba_type_registry.fetch(type_id, JabaType.new(self))
        @type_extension_api.__internal_set_obj(jt)
        @type_extension_api.instance_eval(&d.block)
      end
      @current_definition = nil
    end
      
    op = Output.new
    op.instance_variable_set(:@added_files, @added_files)
    op.instance_variable_set(:@modified_files, @modified_files)
    op.instance_variable_set(:@warnings, @warnings)
    op
  end
  
  ##
  #
  def execute_definitions(file=nil, &block)
    if file
      @toplevel_definition_api.instance_eval(read_file(file), file)
    end
    if block_given?
      file = block.source_location[0]
      @toplevel_definition_api.instance_eval(&block)
    end
  rescue DefinitionError
    raise # Prevent fallthrough to next case
  rescue Exception => e # Catch all errors, including SyntaxErrors, by rescuing Exception
    raise make_definition_error("#{e.class}: #{e.message}", file: file, callstack: e.backtrace)
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
  def make_definition_error(msg, file: nil, callstack: nil, warn: false)
    line = nil
    def_type = nil
    def_id = nil
    where = ''
    def_data = @current_definition
    
    if def_data
      file = def_data.file
      def_type = def_data.type
      def_id = def_data.id
    end

    if file
      # See if callstack includes definition file and extract line number from it, to give exact line if inside a
      # definition, else use definition's line number.
      #
      callstack = caller if !callstack
      call_line = callstack.find{|f| f =~ /#{file}/}
      if call_line
        if call_line !~ /^.*?:(\d+):/
          raise "Failed to extract line number from '#{call_line}'"
        end
        line = $1.to_i
        where << 'at'
      elsif def_data
        line = def_data.line
        where << 'near'
      end
      where << " #{file.basename}"
      where << ":#{line}" if line
    elsif def_data
      where << " in"
      where << " #{def_id}" if def_id
      where << " #{def_type}"
    end

    m = ''
    m << 'Definition error ' if !warn
    m << "#{where}: #{msg.capitalize_first}"

    e = DefinitionError.new(m)
    e.instance_variable_set(:@definition_type, def_type)
    e.instance_variable_set(:@definition_id, def_id)
    e.instance_variable_set(:@file, file)
    e.instance_variable_set(:@line, line)
    e.instance_variable_set(:@where, where)
    e

  end

end

end
