category do
  attr :name do
    help 'Display name of category. Maps to name of solution folder in a Visual Studio solution'
    flags REQUIRED
  end
  
  attr :guid do
    help 'A Globally Unique ID in the form \'0376E589-F783-4B80-DA86-705F2E05304E\'. Required by Visual Studio .sln files'
    flags REQUIRED
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

project do
end