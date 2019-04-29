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
  def initialize(jaba_type)
    @jaba_type = jaba_type
    @attributes = []
    @jaba_type.each_attr do |attr_def|
      attr = Attribute.new(attr_def)
      @attributes << attr
    end
  end
  
end

end
