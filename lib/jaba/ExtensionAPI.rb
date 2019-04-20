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
  def type(t)
    @templ.set_type(t)
  end
  
  ##
  # Set help for the attribute. Required.
  #
  # Options ::
  #
  #   override :: [true|false*] Set to true to overwrite existing help instead of appending to the existing string.
  #
  def help(h, **options)
    @templ.set_help(h, **options)
  end
  
  ##
  # Set any number of flags to control the behaviour of the attribute. Flags should be ORd together, eg ARRAY|ALLOW_DUPES.
  #
  # Options ::
  #
  #   override :: [true|false*] Set to true to overwrite existing flags instead of ORing with existing ones.
  #
  def flags(f, **options)
    @templ.set_flags(f, **options)
  end
  
  ##
  # Set attribute default value. Can be specified as a value or a block.
  #
  # Options ::
  #
  #   override :: [true|false*] Set to true with array values to overwrite existing value instead of extending them. 
  #
  def default(val=nil, **options, &block)
    @templ.set_default(val, **options, &block)
  end
  
  ##
  # Use in conjunction with a choice attribute to specify an array of valid items.
  #
  # Options ::
  #
  #   override :: [true|false*] Set to true with array values to overwrite existing value instead of extending them.
  #
  def items(i, **options)
    @templ.set_items(i, **options)
  end
  
  ##
  # Specify the options this attribute accepts.
  #
  # Options ::
  #
  #   override :: [true|false*] Set to true with array values to overwrite existing value instead of extending them.
  #
  def options(o, **options)
    @templ.set_options(o, **options)
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
  # Options ::
  #
  #   override :: [true|false*] Set to true overwrite any 'base' hooks rather than adding addtional hooks.
  #
  def validate(**options, &block)
    @templ.define_hook(:validate, **options, &block)
  end
  
  ##
  # Validation hook for use only with array attributes. Each element of the array is passed to the block in turn along with any
  # options that were specified in user definitions.
  #
  # validate do |elem, options|
  #   raise "invalid" if elem.nil?
  # end
  #
  # Options ::
  #
  #   override :: [true|false*] Set to true overwrite any 'base' hooks rather than adding addtional hooks.
  #
  def validate_elem(**options, &block)
    @templ.define_hook(:validate_elem, **options, &block)
  end
  
  ##
  # Options ::
  #
  #   override :: [true|false*] Set to true overwrite any 'base' hooks rather than adding addtional hooks.
  #
  def post_set(**options, &block)
    @templ.define_hook(:post_set, **options, &block)
  end
  
  ##
  # Options ::
  #
  #   override :: [true|false*] Set to true overwrite any 'base' hooks rather than adding addtional hooks.
  #
  def make_handle(**options, &block)
    @templ.define_hook(:make_handle, **options, &block)
  end
  
end

end
