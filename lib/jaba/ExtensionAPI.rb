module JABA

# The classes in this file are only needed by the user if extending the core functionality of Jaba.

##
#
module TopLevelExtensionAPI

  ##
  #
  def attr_type(id, **options, &block)
    @obj.define_attr_type(id, **options, &block)
  end
  
  ##
  #
  def attr_flag(id)
    @obj.define_attr_flag(id)
  end
  
  ##
  #
  def define(type, **options, &block)
    @obj.define_type(type, **options, &block)
  end
  
  ##
  #
  def extend(type, **options, &block)
    @obj.extend_type(type, **options, &block)
  end
  
end

##
#
class AttributeTypeAPI < APIBase
  
  ##
  #
  def init_attr_def(&block)
    @obj.set_block(:init_attr_hook, &block)
  end
  
  ##
  #
  def validate_attr_def(&block)
    @obj.set_block(:attr_def_validator, &block)
  end
  
  ##
  #
  def validate(&block)
    @obj.set_block(:value_validator, &block)
  end
  
end

##
# TODO: consider driving attrs from types eg.
#
# reference :platforms do
# end
#
# dir :root do
# end
#
# or maybe
#
# attr_dir :root do
# end
#
class JabaTypeAPI < APIBase
  
  ##
  # Define a new attribute. See AttributeDefinitionAPI class below.
  #
  def attr(id, **options, &block)
    @obj.define_attr(id, **options, &block)
  end
  
  ##
  #
  def extend(id, **options, &block)
    @obj.extend_attr(id, **options, &block)
  end
  
  ##
  #
  def build_nodes(&block)
    @obj.define_hook(:build_nodes, &block)
  end
  
  ##
  # TODO: rationalise all hook handling
  def generate(&block)
    @obj.define_generator(&block)
  end
  
end

##
#
class AttributeDefinitionAPI < APIBase

  ##
  # Set help for the attribute. Required.
  #
  def help(val=nil, &block)
    @obj.set_var(:help, val, &block)
  end
  
  ##
  # Set any number of flags to control the behaviour of the attribute.
  #
  def flags(*flags, &block)
    @obj.set_var(:flags, flags, &block)
  end
  
  ##
  # Set attribute default value. Can be specified as a value or a block.
  #
  def default(val=nil, &block)
    @obj.set_var(:default, val, &block)
  end
  
  ##
  # Called for single value attributes and each element of attrbutes flagged with :array.
  #
  def validate(&block)
    @obj.set_var(:value_validator, &block)
  end
  
  ##
  #
  def post_set(&block)
    @obj.set_var(:post_set, &block)
  end
  
  ##
  #
  def make_handle(&block)
    @obj.set_var(:make_handle, &block)
  end
  
  ##
  #
  def add_property(id, val=nil)
    @obj.set_var(id, val)
  end
  
  ##
  #
  def method_missing(id, val=nil)
    @obj.handle_property(id, val)
  end

end

end
