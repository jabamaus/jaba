module JABA

# The classes in this file are only needed by the user if extending the core functionality of Jaba.

##
#
module TopLevelExtensionAPI

  ##
  #
  def attr_type(id=nil, **options, &block)
    @obj.define_attr_type(id, **options, &block)
  end
  
  ##
  #
  def attr_flag(id=nil)
    @obj.define_attr_flag(id)
  end
  
  ##
  #
  def define(type=nil, **options, &block)
    @obj.define_type(type, **options, &block)
  end
  
  ##
  #
  def extend(type=nil, **options, &block)
    @obj.extend_type(type, **options, &block)
  end
  
end

##
#
class JabaTypeAPI < APIBase
  
  ##
  # Define a new attribute. See AttributeDefinitionAPI class below.
  #
  def attr(id=nil, **options, &block)
    @obj.define_attr(id, **options, &block)
  end
  
  ##
  #
  def extend(id=nil, **options, &block)
    @obj.extend_attr(id, **options, &block)
  end
  
  ##
  # Include one or more shared definitions in this one.
  #
  def include(*shared_definition_ids, args: nil)
    @obj.include_shared(*shared_definition_ids, args: args)
  end
  
end

##
#
class AttributeDefinitionAPI < APIBase

  ##
  # Set the type of the attribute. Optional as a attribute does not require a type.
  #
  def type(val)
    @obj.set_var(:type, val)
  end
  
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
  # Use in conjunction with a choice attribute to specify an array of valid items.
  #
  def items(val=nil, &block)
    @obj.set_var(:items, val, &block)
  end
  
  ##
  # Specify the options this attribute accepts.
  #
  def options(*opts, &block)
    @obj.set_var(:options, opts, &block)
  end
  
  ##
  # Validation hook. Implement attribute validation here. For single value attributes the value of the attribute is passed to the block,
  # along with any options that were specified in user definitions. Options can be ommitted from the block arguments if not required.
  #
  # validate do |val, options|
  #   raise "invalid" if val.nil?
  # end
  #
  # For attributes flagged with ARRAY 'val' will be an array and no options will be passed as options are associated with the elements.
  # To validate element by element with options use validate_elem.
  #
  # validate do |val|
  #   raise "invalid" if val.empty?
  # end
  #
  def validate(&block)
    @obj.set_var(:validate, &block)
  end
  
  ##
  # Validation hook for use only with array attributes. Each element of the array is passed to the block in turn along with any
  # options that were specified in user definitions.
  #
  # validate do |elem, options|
  #   raise "invalid" if elem.nil?
  # end
  #
  def validate_elem(&block)
    @obj.set_var(:validate_elem, &block)
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
  
end

end
