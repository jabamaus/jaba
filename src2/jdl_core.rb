module JABA
  class Documentable
    def initialize
      @title = nil
      @notes = []
      @examples = []
    end
    def title(t) = @title = t
    def note(n) = @notes << n
    def example(e) = @examples << e
    def __validate
      __check(:@title)
    end
    def __check(var)
      JABA.error('var must be specified as a symbol') if !var.symbol?
      if instance_variable_get(var).nil?
        JABA.error("'#{describe}' requires '#{var.to_s.delete_prefix('@')}' to be specified")
      end
    end
  end

  class Definition < Documentable
    def initialize(name)
      super()
      @name = name
    end
    def name = @name
    def describe = "'#{name.inspect_unquoted}'"
    def __validate
      super
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
    def initialize(name, variant, attr_type)
      super(name)
      @variant = variant
      @attr_type = attr_type
      @flags = nil
      @default = nil
    end
    def variant = @variant
    def describe
      "'#{@name.inspect_unquoted}' #{@variant == :single ? "" : "#{@variant} "}attribute"
    end
    def flags(*flags) = @flags = flags
    def default(val=nil, &block)
      @default = block_given? ? block : val
    end
    def __validate
      super

    end
  end

  class AttributeSingleDefinition < AttributeDefinition
    def initialize(name, attr_type)
      super(name, :single, attr_type)
    end
    def __validate
      super
      
    end
  end
  
  class AttributeArrayDefinition < AttributeDefinition
    def initialize(name, attr_type)
      super(name, :array, attr_type)
    end
  end

  class AttributeHashDefinition < AttributeDefinition
    def initialize(name, attr_type)
      super(name, :hash, attr_type)
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
      # TODO: automatically make class name from typeid
      attr_type_class = case type
      when :bool
        JABA::AttributeTypeBool
      else
        JABA::AttributeTypeNull
      end
      attr_type = attr_type_class.singleton
      attr_def = JABA::AttributeSingleDefinition.new(attr_name, attr_type)
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
