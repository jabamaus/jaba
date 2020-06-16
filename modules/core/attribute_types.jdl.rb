attr_type :string do
  help 'String attribute type. Only explicit strings will be accepted. Symbols are not valid.'
  default ''
  validate_value do |value|
    if !value.string?
      fail "'#{value}' must be a string but was a '#{value.class}'"
    end
  end
end

attr_type :symbol do
  help 'Symbol attribute type. Only explicit symbols will be accepted. Strings are not valid.'
  validate_value do |value|
    if !value.symbol?
      fail "'#{value}' must be a symbol but was a '#{value.class}'"
    end
  end
end

attr_type :symbol_or_string do
  help 'Symbol or string attribute type. Only explicit strings or symbols will be accepted.'
  default ''
  validate_value do |value|
    if !value.symbol? && !value.string?
      fail "'#{value}' must be a symbol or a string but was a '#{value.class}'"
    end
  end
end

attr_type :bool do
  help "Boolean attribute type. Accepts [true|false]. Defaults to false"
  default false
  post_init_attr_def do
    if attr_array?
      flags :nosort, :allow_dupes
    end
  end
   validate_value do |value|
    if !value.boolean?
      fail ":bool attributes only accept [true|false] but got '#{value}'"
    end
  end
end

attr_type :choice do
  help 'Choice attribute type. Can take exactly one of a set of unique values'
  init_attr_def do
    define_array_property :items
  end
  post_init_attr_def do
    if items.empty?
      fail "'items' must be set"
    elsif items.uniq!
      warn "'items' contains duplicates"
    end
  end
  validate_value do |value|
    if !items.include?(value)
      fail "must be one of #{items} but was '#{value}'"
    end
  end
end

attr_type :dir do
  help 'Directory attribute type. Validates that value is a string path representing a directory'
  validate_value do |dir|
    dir.cleanpath(validate: true) do |clean|
      warn "Directory '#{dir}' not specified cleanly. Should be '#{clean}'."
    end
  end
end

attr_type :file do
  help 'File attribute type. Validates that value is a string path representing a file'
  validate_value do |file|
    file.cleanpath(validate: true) do |clean|
      warn "File '#{file}' not specified cleanly. Should be '#{clean}'."
    end
  end
end

attr_type :src_spec do
  title 'Source file specification pattern'
  help 'Can be file glob match an explicit path or a directory'
  validate_value do |path|
    path.cleanpath(validate: true) do |clean|
      warn "Src spec '#{path}' not specified cleanly. Should be '#{clean}'."
    end
  end
end

attr_type :reference do
  help 'Reference attribute type'
  init_attr_def do
    define_property :referenced_type
    define_property :make_handle # TODO: flag as block or validate as such
  end
  post_init_attr_def do
    rt = referenced_type
    if rt.nil?
      fail "'referenced_type' must be set"
    end
    if jaba_type.id != rt
      jaba_type.dependencies rt
    end
  end
end

# TODO: generate UUID from string
attr_type :uuid do
  title 'UUID attribute type'
  validate_value do |uuid|
    if uuid !~ /[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/
      fail 'Must be an all upper case GUID in the form 0376E589-F783-4B80-DA86-705F2E05304E'
    end
  end
end