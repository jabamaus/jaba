module JABA

##
#
class Attribute

  ##
  #
  def initialize(attr_def)
    @def = attr_def
  end
  
end

##
#
class JabaObject

  ##
  #
  def initialize(jaba_type, def_data)
    @jaba_type = jaba_type
    @def_data = def_data
    @attributes = []
    @jaba_type.each_attr do |attr_def|
      attr = Attribute.new(attr_def)
      @attributes << attr
    end
    @generators = []
  end
  
  ##
  #
  def define_generator(&block)
    @generators << block
  end
  
  ##
  #
  def call_generators
    @generators.each do |block|
      block.call
    end
  end
  
  ##
  #
  def include_shared(ids, args: [])
  end
  
  ##
  #
  def handle_attr(id, called_from_definitions, *args, **key_value_args, &block)
  end
  
end

end
