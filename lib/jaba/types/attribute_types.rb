# frozen_string_literal: true

# TODO: add help string to flags
attr_flag :allow_dupes
attr_flag :no_check_exist
attr_flag :read_only
attr_flag :required
attr_flag :unordered

# TODO: think about compatibility of flags to attribute types, eg :no_make_rel_to_genroot only applies to
# :path, :file and :dir attrs

##
#
attr_type :bool do
  init_attr_def do
    default false
    flags :unordered, :allow_dupes
  end
  
  validate_value do |value|
    if !value.boolean?
      raise ':bool attributes only accept [true|false]'
    end
  end
end

##
#
attr_type :choice do
  init_attr_def do
    add_property :items, []
  end
  
  validate_attr_def do
    if items.empty?
      raise "'items' must be set"
    end
  end
  
  validate_value do |value|
    if !items.include?(value)
      raise "must be one of #{items}"
    end
  end
end

##
#
attr_type :dir do
end

##
#
attr_type :file do
end

##
#
attr_type :path do
end

##
#
attr_type :keyvalue do
  init_attr_def do
    default KeyValue.new
  end
end

##
#
attr_type :reference do
  init_attr_def do
    add_property :referenced_type, nil
  end
  
  validate_attr_def do
    rt = referenced_type
    if rt.nil?
      raise "'referenced_type' must be set"
    end
    if jaba_type.type != rt
      jaba_type.dependencies rt
    end
  end
end
