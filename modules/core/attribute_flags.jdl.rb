# General attribute flags
#
attr_flag :required do
  note 'Specifies that the definition writer must supply a value for this attribute'
  compatibility do
    fail ':required can only be specified if no default specified' if default_set?
  end
end

attr_flag :read_only do
  note 'Specifies that the attribute can only be read and not set from user definitions. The value will be initialised inside Jaba'
  compatibility do
    warn 'Reference attribute does not need to be flagged with :read_only as they always are' if type == :reference
  end
end

attr_flag :expose do
  note 'Attributes flagged with :expose that are in a type that is then referenced by another type will have their attribute ' \
       'name automatically imported as a read only property. An example of this is the windows? attribute in :platform type'
end

# Array attribute flags
#
attr_flag :allow_dupes do
  note 'Allows array attributes to contain duplicates. If not specified duplicates are stripped'
  compatibility do
    fail ':allow_dupes is only allowed on array attributes' if variant != :array
  end
end

attr_flag :nosort do
  note 'Allows array attributes to remain in the order they are set in. If not specified arrays are sorted'
  compatibility do
    fail ':nosort is only allowed on array attributes' if variant != :array
  end
end

# File/dir/path attribute flags
# TODO: use this
attr_flag :no_check_exist do
  note 'Use with file, dir or path attributes to disable checking if the path exists on disk, eg if it will get generated'
  compatibility do
    fail ":no_check_exist can only be used with :file and :dir attribute types" if ![:file, :dir].include?(type)
  end
end
