JDL.method 'puts' do
  title 'Prints a line to stdout'
  on_called do |str| puts str end
end

JDL.method 'shared' do
  title 'Define a shared definition'
  on_called do end
end

JDL.node 'app' do
  title 'Define an app'
end

JDL.node 'lib' do
  title 'Define a lib'
end

JDL.node 'app|config' do
end

JDL.node 'app|config|rule' do
end

JDL.attr 'app|config|rule|input', type: :src_spec do
end

JDL.method 'app|include', 'lib|include' do
  title 'Include a shared definition'
  on_called do |id|
    @context.include_shared(id)
  end
end

JDL.attr 'app|root', 'lib|root', type: :string do
  flags []
end

JDL.method 'glob' do
  title 'glob files'
  on_called do
  end
end
