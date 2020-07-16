define :category do
  
  title 'Project category type'

  attr :name, type: :string do
    title 'Display name of category'
    note 'Maps to name of solution folder in a Visual Studio solution'
    flags :required
  end
  
  attr :parent, type: :reference do
    title 'Parent category'
    note 'Use this to build a category hierarchy that can be used to classify projects in workspaces'
    referenced_type :category
  end
  
end

category :App do
  name 'Apps'
end
