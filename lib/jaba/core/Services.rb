require_relative 'Utils'

module JABA

class Services

  attr_reader :input
  
  ##
  # Records information about each definition the user has made.
  #
  Definition = Struct.new(:id, :file, :line, :block)
  
  ##
  #
  def initialize
    @input = Input.new
    @input.instance_variable_set(:@definitions_block, nil)
    @input.root = Dir.getwd
    @input.verbose = false
    
    @info = []
    @warnings = []
    
    @added_files = []
    @modified_file = []
    
    @definition_lookup = {}
    
    @file_read_cache = {}
    
    @globals = Globals.new
    @globals.__internal_set_services(self)
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
  # type can be eg :project, :workspace, :target, :shared, :attr, :attr_type etc,
  #
  def register_definition(type, id, **options, &block)
    if caller[1] !~ /^(.*)?:(\d+):/
      raise "Could not determine file and line number for '#{type}' '#{id}'"
    end
    file = $1
    line = $2.to_i
    
    if !id
      definition_error("'#{type}' must have an id", nil, type, file: file)
    end
    
    if (!(id.is_a?(Symbol) or id.is_a?(String)) or id !~ /^[a-zA-Z0-9_.]+$/)
      definition_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'", nil, type, file: file)
    end
    
    if definition_defined?(id)
      definition_error("'#{id}' multiply defined", id, type, file: file)
    end
    
    @definition_lookup[id] = Definition.new(id, file, line, block)
  end
  
  ##
  #
  def get_definition(id, fail_if_not_found: true)
    d = @definition_lookup[id]
    raise "No '#{id}' definition found" if (!d and fail_if_not_found)
    d
  end

  ##
  #
  def definition_defined?(id)
    @definition_lookup.has_key?(id)
  end
  
  ##
  #
  def definition_warning(msg, definition_id, definition_type, file: nil, callstack: nil)
    e = make_definition_error(msg, definition_id, definition_type, file, callstack, warning: true)
    warning e.message
  end
  
  ##
  #
  def definition_error(msg, definition_id, definition_type, file: nil, callstack: nil)
    raise make_definition_error(msg, definition_id, definition_type, file, callstack)
  end
  
  ##
  #
  def read_file(file, encoding: nil, desc: nil)
    puts "#{desc} '#{file}'" if (desc and input.verbose?)
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
    if input.definitions
      execute_definitions(&input.definitions)
    else
      load_definitions
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
    @globals.instance_eval(&block) if block_given?
    @globals.instance_eval(read_file(file), file) if file
  rescue DefinitionError
    raise
  rescue Exception => e # Catch all errors, including SyntaxErrors, by rescuing Exception
    definition_error("#{e.class}: #{e.message}", nil, nil, file: file, callstack: e.backtrace)
  end
  
  ##
  #
  def load_definitions
  end
  
  ##
  #
  def make_definition_error(msg, definition_id, definition_type, file, callstack, warning: false)
    line = nil
    where = ''

    if definition_id
      def_data = get_definition(definition_id)
      file = def_data.file
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
    elsif definition_id
      where << " in '#{definition_id}' #{definition_type}"
    end

    m = ''
    m << 'Definition error ' if !warning
    m << "#{where}: #{msg.capitalize_first}"

    e = DefinitionError.new(m)
    e.instance_variable_set(:@definition_id, definition_id)
    e.instance_variable_set(:@definition_type, definition_type)
    e.instance_variable_set(:@file, file)
    e.instance_variable_set(:@line, line)
    e.instance_variable_set(:@where, where)
    e

  end
  
end

end
