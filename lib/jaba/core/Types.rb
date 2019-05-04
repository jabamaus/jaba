attr_flag :required
attr_flag :array
attr_flag :unordered
attr_flag :allow_dupes

##
#
attr_type :bool do
end

##
#
attr_type :choice do
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
end

##
#
attr_type :reference do
end

##
#
define :target do
end

##
#
define :category do
  attr :name do
    help 'Display name of category. Maps to name of solution folder in a Visual Studio solution'
    flags :required
  end
  
  attr :guid do
    help 'A Globally Unique ID in the form \'0376E589-F783-4B80-DA86-705F2E05304E\'. Required by Visual Studio .sln files'
    flags :required
    validate do |val|
      if val !~ /[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/
        raise 'Must be an all upper case GUID in the form 0376E589-F783-4B80-DA86-705F2E05304E'
      end
    end
  end
  
  attr :parent do
    help 'Makes this category a child of the specified category.'
    type :reference
  end
end

##
#
define :text do
  attr :filename do
    help 'Path to the filename to be generated'
    type :file
    flags :required
  end
  
  attr :content do
    help 'Directly set content of file as a string'
  end
  
  attr :line do
    help 'Set content of file line by line'
    flags :array, :allow_dupes, :unordered
  end
  
  attr :eol do
    help 'Newline style'
    type :choice
    items [:native, :unix, :windows]
    default :native
  end
end

##
#
define :project do
end

##
#
define :workspace do
end
