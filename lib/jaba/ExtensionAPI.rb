module JABA

# The classes in this file are only needed by the user if extending the core functionality of Jaba.

##
#
module TopLevelDefinitionExtensionAPI

  ##
  #
  def attr_type(id=nil, **options, &block)
    @obj.register_attr_type(id, **options, &block)
  end
  
  ##
  #
  def attr_flag(id=nil)
    @obj.register_attr_flag(id)
  end
  
  ##
  #
  def extend_target(**options, &block)
    @obj.extend_type(:target, **options, &block)
  end
  
  ##
  #
  def extend_project(**options, &block)
    @obj.extend_type(:project, **options, &block)
  end
  
  ##
  #
  def extend_workspace(**options, &block)
    @obj.extend_type(:workspace, **options, &block)
  end
  
  ##
  #
  def extend_category(**options, &block)
    @obj.extend_type(:category, **options, &block)
  end
  
end

##
#
class DefinitionTypeExtensionAPI < DefinitionAPI
  
  ##
  # Define a new attribute. See AttributeDefinitionAPI class below.
  #
  def attr(id=nil, **options, &block)
    @obj.register_attr(id, **options, &block)
  end
  
  ##
  #
  def override_attr(id=nil, **options, &block)
    @obj.override_attr(id, **options, &block)
  end
  
end

##
#
class AttributeDefinitionAPI < DefinitionAPI

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
  # Set any number of flags to control the behaviour of the attribute. Flags should be ORd together, eg ARRAY|ALLOW_DUPES.
  #
  def flags(val=nil, &block)
    @obj.set_var(:flags, val, &block)
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
  def options(v=nil, &block)
    @obj.set_var(:options, val, &block)
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
