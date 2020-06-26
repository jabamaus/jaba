define :category do
  
  title 'Project category'

  attr :name do
    title 'Display name of category'
    help 'Maps to name of solution folder in a Visual Studio solution'
    flags :required
  end
  
  attr :guid, type: :uuid do
    title 'Globally unique id (GUID)'
    help 'Seeded by <name>. Required by Visual Studio .sln files'
    default { name }
  end
  
  attr :parent, type: :reference do
    title 'Parent category'
    help 'Use this to build a category hierarchy that can be used to classify projects in workspaces'
    referenced_type :category
  end
  
end

category :App do
  name 'Apps'
end
