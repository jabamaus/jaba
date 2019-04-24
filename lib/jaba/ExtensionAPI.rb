module JABA

# The classes in this file are only needed by the user if extending the core functionality of Jaba.

##
#
module GlobalExtensions

  ##
  # Define a new attribute. See AttributeDefinition class below.
  #
  def attr(id=nil, **options, &block)
    @services.register_definition(:attr, id, **options, &block)
  end
  
  ##
  # Define a new attribute type. Advanced. Used for extending Jaba.
  #
  def attr_type(id=nil, **options, &block)
    @services.register_definition(:attr_type, id, **options, &block)
  end
  
end

##
# For example this attribute definition:
#
# attr :my_attr do
#   help 'My help string explaining what the attr does'
#   type :path
#   flags ARRAY|UNORDERED|ALLOW_DUPES
#   options [:group, :force]
# end
#
# Would allow definitions to use the my_attr attribute eg:
#
# shared :my_shared do
#   my_attr ['/path1', '/path2'], :group
# end
#
class AttributeDefinition

  ##
  # Set the type of the attribute. Optional as a attribute does not require a type.
  #
  def type(val)
    @templ.set_var(:type, val)
  end
  
  ##
  # Set help for the attribute. Required.
  #
  def help(val=nil, &block)
    @templ.set_var(:help, val, &block)
  end
  
  ##
  # Set any number of flags to control the behaviour of the attribute. Flags should be ORd together, eg ARRAY|ALLOW_DUPES.
  #
  def flags(val=nil, &block)
    @templ.set_var(:flags, val, &block)
  end
  
  ##
  # Set attribute default value. Can be specified as a value or a block.
  #
  def default(val=nil, &block)
    @templ.set_var(:default, val, &block)
  end
  
  ##
  # Use in conjunction with a choice attribute to specify an array of valid items.
  #
  def items(val=nil, &block)
    @templ.set_var(:items, val, &block)
  end
  
  ##
  # Specify the options this attribute accepts.
  #
  def options(v=nil, &block)
    @templ.set_var(:options, val, &block)
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
    @templ.set_var(:validate, &block)
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
    @templ.set_var(:validate_elem, &block)
  end
  
  ##
  #
  def post_set(&block)
    @templ.set_var(:post_set, &block)
  end
  
  ##
  #
  def make_handle(&block)
    @templ.set_var(:make_handle, &block)
  end
  
end

end
