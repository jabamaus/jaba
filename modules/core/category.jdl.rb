define :category do
  
  title 'Project category'

  attr :name do
    title 'Display name of category'
    help 'Maps to name of solution folder in a Visual Studio solution'
    flags :required
  end
  
  attr :guid, type: :uuid do
    title 'Globally unique id (GUID)'
    help 'Must be of the form \'0376E589-F783-4B80-DA86-705F2E05304E\'. Required by Visual Studio .sln files'
    flags :required
  end
  
  attr :parent, type: :reference do
    title 'Parent category'
    help 'Use this to build a category hierarchy that can be used to classify projects in workspaces'
    referenced_type :category
  end
  
end

category :App do
  name 'Apps'
  guid '43F42D01-78C0-416E-8979-2807134DB488'
end