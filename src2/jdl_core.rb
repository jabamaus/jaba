module JDL
  FlagDefinitionAPI = APIBuilder.define(:title, :note, :example, :compatible?, :init_attr_def)
  AttributeSingleDefinitionAPI = APIBuilder.define(:title, :note, :example, :flags, :flag_options, :default)
  MethodDefinitionAPI = APIBuilder.define(:title, :note, :example, :on_called)

  # BaseAPI is the blankest possible slate
  class BaseAPI < BasicObject
    undef_method(:!)
    undef_method(:!=)
    undef_method(:==)
    undef_method(:equal?)
    undef_method(:__id__)
    def self.singleton; @instance ||= self.new; end

    def __internal_set_node(n) = @node = n
  end

  class TopLevelAPI < BaseAPI
    @attr_defs = []
    def self.attr_defs = @attr_defs
  end

  def self.flag(name, &block)
    fd = JABA::FlagDefinition.new(name)
    FlagDefinitionAPI.execute(fd, &block) if block_given?
  end

  def self.node(*paths, &block)
    paths.each do |path|
      node_api_klass = api_class_from_path(path, create: true)
      parent_path, item = path.split_jdl_path
      parent_klass = api_class_from_path(parent_path)
      parent_klass.define_method(item) do |*args, **kwargs, &node_block|
        $last_call_location = ::Kernel.caller_locations(1, 1)[0]
        JABA.context.create_node(node_api_klass, *args, **kwargs, &node_block)
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
      AttributeSingleDefinitionAPI.execute(attr_def, &block) if block_given?
      attr_def.__validate
      klass.attr_defs << attr_def
    end
  end

  def self.method(*paths, &block)
    paths.each do |path|
      parent_path, method_name = path.split_jdl_path
      klass = api_class_from_path(parent_path)
      meth_def = JABA::MethodDefinition.new(method_name)
      MethodDefinitionAPI.execute(meth_def, &block) if block_given?
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
    name = "#{path.split("|").map { |p| p.capitalize_first }.join}API"
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
