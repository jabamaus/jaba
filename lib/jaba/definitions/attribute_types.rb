# TODO: think about compatibility of flags to attribute types

attr_type :string do
  
  help 'String attribute type. Only actual strings will be accepted. Symbols are not valid.'

  validate_value do |value|
    if !value.string?
      fail 'Value must be a string'
    end
  end

end

attr_type :bool do
  
  help "Boolean attribute type. Accepts [true|false]. Defaults to false"

  init_attr_def do
    default false
    flags :unordered, :allow_dupes
  end
  
  validate_value do |value|
    if !value.boolean?
      fail ':bool attributes only accept [true|false]'
    end
  end

end

attr_type :choice do

  help 'Choice attribute type. Can take exactly one of a set of unique values'

  init_attr_def do
    define_array_property :items
  end
  
  validate_attr_def do
    if items.empty?
      fail "'items' must be set"
    elsif items.uniq!
      warn "'items' contains duplicates"
    end
  end
  
  validate_value do |value|
    if !items.include?(value)
      fail "must be one of #{items}"
    end
  end

end

attr_type :dir do
  help 'Directory attribute type. Validates that value is a string path representing a directory'
end

attr_type :file do
  help 'File attribute type. Validates that value is a string path representing a file'
end

attr_type :path do
  help 'Path attribute type. Validates that value is a string path representing either a file or a directory'
end

attr_type :reference do

  help 'Reference attribute type'

  init_attr_def do
    define_property :referenced_type
    define_property :make_handle # TODO: flag as block or validate as such
  end
  
  validate_attr_def do
    rt = referenced_type
    if rt.nil?
      fail "'referenced_type' must be set"
    end
    if jaba_type._ID != rt
      jaba_type.dependencies rt
    end
  end

end
