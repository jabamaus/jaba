module JABA

##
# Manages shared data that is common to Attributes instanced from this template.
#
class AttributeTemplate

  ##
  #
  def initialize(name)
    @name = name

    @default = nil
    @flags = nil
    @help = nil
    @items = nil
    @options = nil
    @type = nil
  end
  
  ##
  #
  def set_var(:var, val=nil, &block)
    if block_given?
      if !val.nil?
        @services.definition_error('Must provide a default value or a block but not both')
      end
      instance_variable_set(":@#{var}", block)
    else
      instance_variable_set(":@#{var}", val)
    end
  end
  
end

class Attribute
end

end
