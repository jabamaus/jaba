method 'puts' do
  title 'Prints a line to stdout'
  on_called do |str| puts str end
end

attr 'shared', type: :block do
  title 'Define a shared definition'
  #set do |id, &block|
  #  services.register_shared(id, &block)
  #end
end

node 'app' do
  title 'Define an app'
end

node 'lib' do
  title 'Define a lib'
end

node 'app|config' do
end

node 'app|config|rule' do
end

attr 'app|config|rule|input', type: :src_spec do
end

method 'app|include', 'lib|include' do
  title 'Include a shared definition'
  on_called do |id|
    services.include_shared(id)
  end
end

attr 'app|root', 'lib|root', type: :string do
  flags []
end

method 'glob' do
  title 'glob files'
  on_called do
  end
end
