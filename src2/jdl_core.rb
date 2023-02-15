module JABA

  class Definition
    def initialize(name)
      @name = name
      @title = nil
    end
    def name = @name
    def title(t) = @title = t
    def __validate ; end
    def __check(var)
      JABA.error('var must be specified as a symbol') if !var.symbol?
      if instance_variable_get(var).nil?
        JABA.error("'#{name}' requires '#{var.to_s.delete_prefix('@')}' to be specified")
      end
    end
  end
  
  class MethodDefinition < Definition
    def initialize(name)
      super
      @on_called = nil
    end
    def on_called(&block) = @on_called = block
    def __validate
      super
      __check(:@on_called)
    end
  end
  
  class AttributeDefinition < Definition
    def initialize(name, variant)
      super(name)
      @variant = variant
      @flags = nil
    end
    def variant = @variant
    def flags(*flags) = @flags = flags
    def __validate
      super

    end
  end

  class AttributeSingleDefinition < AttributeDefinition
    def initialize(name)
      super(name, :single)
    end
  end
  
  class AttributeArrayDefinition < AttributeDefinition
    def initialize(name)
      super(name, :array)
    end
  end

  class AttributeHashDefinition < AttributeDefinition
    def initialize(name)
      super(name, :hash)
    end
  end
end

module JDL
  # BaseAPI is the blankest possible slate
  class BaseAPI < BasicObject
    undef_method(:!)
    undef_method(:!=)
    undef_method(:==)
    undef_method(:equal?)
    undef_method(:__id__)
    def self.singleton ; @instance ||= self.new ; end
    def __internal_set_context(c) = @context = c
    def __internal_set_node(n) = @node = n
  end

  class TopLevelAPI < BaseAPI
    @attr_defs = []
    def self.attr_defs = @attr_defs
  end

  def self.node(*paths, &block)
    paths.each do |path|
      node_api_klass = api_class_from_path(path, create: true)
      parent_path, item = path.split_jdl_path
      parent_klass = api_class_from_path(parent_path)
      parent_klass.define_method(item) do |*args, **kwargs, &node_block|
        $last_call_location = ::Kernel.caller_locations(1, 1)[0]
        @context.create_node(node_api_klass, *args, **kwargs, &node_block)
      end
    end
  end

  def self.attr(*paths, type: nil, &block)
    paths.each do |path|
      parent_path, attr_name = path.split_jdl_path
      klass = api_class_from_path(parent_path)
      klass.define_method(attr_name) do |*args, **kwargs, &attr_block|
        $last_call_location = ::Kernel.caller_locations(1, 1)[0]
        @node.handle_attr(attr_name, *args, **kwargs, &attr_block)
      end
      attr_def = JABA::AttributeSingleDefinition.new(attr_name)
      attr_def.instance_eval(&block) if block_given?
      attr_def.__validate
      klass.attr_defs << attr_def
    end
  end

  def self.method(*paths, &block)
    paths.each do |path|
      parent_path, method_name = path.split_jdl_path
      klass = api_class_from_path(parent_path)
      meth_def = JABA::MethodDefinition.new(method_name)
      meth_def.instance_eval(&block) if block_given?
      meth_def.__validate
      klass.define_method(method_name) do |*args, **kwargs|
        $last_call_location = ::Kernel.caller_locations(1, 1)[0]
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
      klass = Class.new(BaseAPI)
      klass.class_eval do
        @attr_defs = []
        def self.attr_defs = @attr_defs
      end
      JDL.const_set(name, klass)
    else
      JDL.const_get(name)
    end
  end

end
