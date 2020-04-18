# TODO: think about compatibility of flags to attribute types, eg :no_make_rel_to_genroot only applies to
# :path, :file and :dir attrs

attr_type :bool do
  
  help 'TODO'

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

  help 'TODO'

  init_attr_def do
    set_property :items, []
  end
  
  validate_attr_def do
    if items.empty?
      fail "'items' must be set"
    end
  end
  
  validate_value do |value|
    if !items.include?(value)
      fail "must be one of #{items}"
    end
  end

end

attr_type :dir do
  help 'TODO'
end

attr_type :file do
  help 'TODO'
end

attr_type :path do
  help 'TODO'
end

attr_type :keyvalue do

  help 'TODO'

  init_attr_def do
    default KeyValue.new
  end

end

attr_type :reference do

  help 'TODO'

  init_attr_def do
    set_property :referenced_type, nil
  end
  
  validate_attr_def do
    rt = referenced_type
    if rt.nil?
      fail "'referenced_type' must be set"
    end
    if jaba_type.type != rt
      jaba_type.dependencies rt
    end
  end

end