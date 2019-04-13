module JABA

class Services

  attr_reader :input
  
  ##
  #
  def initialize
    @input = Input.new
    @input.instance_variable_set(:@definitions_block, nil)
    @input.verbose = false
    @file_read_cache = {}
    @top_level_api = TopLevelUserDefinitionAPI.new
    @top_level_api.instance_variable_set(:@services, self)
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
    op
  end
  
  ##
  #
  def execute_definitions(file=nil, &block)
    @top_level_api.instance_eval(&block) if block_given?
    @top_level_api.instance_eval(read_file(file), file) if file
  rescue DefinitionError
    raise
  rescue Exception => e # Catch all errors, including SyntaxErrors, by rescuing Exception
    definition_error("#{e.class}: #{e.message}", nil, nil, file: file, callstack: e.backtrace)
  end
  
  ##
  #
  def load_definitions
  end
  
end

##
#
class Class
  
  ##
  # Allow setting and getting a block as a member variable.
  #
  def attr_block(*attrs)
    attrs.each do |a|
      self.class_eval "def #{a}(&block); block_given? ? @#{a}_block = block : @#{a}_block ; end"
    end
  end
  
  ##
  # Defines a boolean attribute(s). Boolean member variable must be initialised.
  #
  def attr_boolean(*attrs)
    attrs.each do |a|
      self.class_eval("def #{a}?; @#{a}; end")
      self.class_eval("def #{a}=(val); @#{a}=val; end")
    end
  end
  
end

end
