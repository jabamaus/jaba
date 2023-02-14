module JABA

  class Definition
    def initialize
      @title = nil
    end
    def title(t) = @title = t
  end
  
  class MethodDefinition < Definition
    def initialize
      super
      @on_called = nil
    end
    def on_called(&block) = @on_called = block
  end
  
  class AttributeDefinition < Definition
    def initialize
      super
      @flags = nil
    end
    def flags(*flags) = @flags = flags
  end

module JDL
  # JDLBaseAPI is the blankest possible slate
  class JDLBaseAPI < BasicObject
    undef_method(:!)
    undef_method(:!=)
    undef_method(:==)
    undef_method(:equal?)
    undef_method(:__id__)
    def self.singleton ; @instance ||= self.new ; end
    def __internal_set_context(c) = @context = c
  end

  class TopLevelAPI < JDLBaseAPI ; end

  def self.node(*paths, &block)
    paths.each do |path|
      node_api_klass = api_class_from_path(path, create: true)
      parent_path, item = path.split_jdl_path
      parent_klass = api_class_from_path(parent_path)
      parent_klass.define_method(item) do |*args, **kwargs, &node_block|
        id = args.shift
        @context.create_node(node_api_klass, id, &node_block)
      end
    end
  end

  def self.attr(*paths, type: nil, &block)
    paths.each do |path|
      parent_path, attr_name = path.split_jdl_path
      klass = api_class_from_path(parent_path)
      attr_def = AttributeDefinition.new
      attr_def.instance_eval(&block) if block_given?
      klass.define_method(attr_name) do |*args, **kwargs|
        attr_def
      end
    end
  end

  def self.method(*paths, &block)
    paths.each do |path|
      parent_path, method_name = path.split_jdl_path
      klass = api_class_from_path(parent_path)
      meth_def = MethodDefinition.new
      meth_def.instance_eval(&block) if block_given?
      klass.define_method(method_name) do |*args, **kwargs|
        meth_def.instance_variable_get(:@on_called).call(*args, **kwargs)
      end
    end
  end

  def self.api_class_from_path(path, create: false)
    if path.nil?
      return TopLevelAPI
    end
    name = "#{path.split('|').map{|p| p.capitalize_first}.join}API"
    if create
      klass = Class.new(JDLBaseAPI)
      JDL.const_set(name, klass)
    else
      JDL.const_get(name)
    end
  end
end

JDL.method 'puts' do
  title 'Prints a line to stdout'
  on_called do |str| puts str end
end

JDL.attr 'shared', type: :block do
  title 'Define a shared definition'
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
    services.include_shared(id)
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

end