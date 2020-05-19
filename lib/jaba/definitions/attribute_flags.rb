# General attribute flags
#
attr_flag :required do
  help 'Specifies that the definition writer must supply a value for this attribute'
end

attr_flag :read_only do
  help 'Specifies that the attribute can only be read and not set from user definitions. The value will be initialised inside Jaba'
end

attr_flag :expose do
  help 'Attributes flagged with :expose that are in a type that is then referenced by another type will have their attribute ' \
       'name automatically imported as a read only property. An example of this is the win32? attribute in :platform type'
end

# Array attribute flags
#
attr_flag :allow_dupes do
  help 'Allows array attributes to contain duplicates. If not specified duplicates are stripped'
end

attr_flag :unordered do
  help 'Allows array attributes to remain in the order they are set in. If not specified arrays are sorted'
end

# File/dir/path attribute flags
#
attr_flag :no_check_exist do
  help 'Use with file, dir or path attributes to disable checking if the path exists on disk, eg if it will get generated'
end
