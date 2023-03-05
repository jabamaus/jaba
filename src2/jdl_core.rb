module JDL
  FlagDefinitionAPI = APIBuilder.define(:title, :note, :example, :compatible?)
  AttributeDefinitionAPI = APIBuilder.define(:title, :note, :example, :flags, :flag_options, :items, :value_option, :validate, :validate_key, :default)
  MethodDefinitionAPI = APIBuilder.define(:title, :note, :example, :on_called)

  # BaseAPI is the blankest possible slate
  class BaseAPI < BasicObject
    undef_method :!, :!=, :==, :equal?, :__id__
    def self.singleton = @instance ||= self.new
    def self.attr_defs = @attr_defs ||= []

    def __internal_set_node(n) = @node = n
  end

  class TopLevelAPI < BaseAPI; end

  def self.flag(name, &block)
    fd = JABA::FlagDefinition.new(calling_location, name)
    FlagDefinitionAPI.execute(fd, &block) if block_given?
  end

  def self.node(path, &block)
    node_api_klass = api_class_from_path(path, create: true)
    parent_path, item = path.split_jdl_path
    parent_klass = api_class_from_path(parent_path)
    parent_klass.define_method(item) do |*args, **kwargs, &node_block|
      $last_call_location = ::Kernel.caller_locations(1, 1)[0]
      JABA.context.create_node(node_api_klass, *args, **kwargs, &node_block)
    end
  end

  def self.attr(*paths, type: nil, &block)
    process_attr(calling_location, paths, JABA::AttributeSingleDefinition, type, &block)
  end

  def self.attr_array(*paths, type: nil, &block)
    process_attr(calling_location, paths, JABA::AttributeArrayDefinition, type, &block)
  end

  def self.attr_hash(*paths, type: nil, &block)
    process_attr(calling_location, paths, JABA::AttributeHashDefinition, type, &block)
  end

  def self.method(name, scope:, &block)
    src_loc = calling_location
    Array(scope).each do |s|
      parent_path = if s == :top_level
          nil
        elsif s == :global
          :global
        else
          s
        end

      klass = api_class_from_path(parent_path)
      meth_def = JABA::MethodDefinition.new(src_loc, name)
      MethodDefinitionAPI.execute(meth_def, &block) if block_given?
      meth_def.post_create
      klass.define_method(name) do |*args, **kwargs|
        $last_call_location = ::Kernel.caller_locations(1, 1)[0]
        meth_def.on_called&.call(*args, **kwargs)
      end
    end
  end

  def self.api_class_from_path(path, create: false)
    if path.nil?
      return TopLevelAPI
    elsif path == :global
      return BaseAPI
    end
    name = "#{path.split("|").map { |p| p.capitalize_first }.join}API"
    if create
      JDL.const_set(name, Class.new(BaseAPI))
    else
      JDL.const_get(name)
    end
  end

  private

  def self.process_attr(src_loc, paths, def_klass, type, &block)
    paths.each do |path|
      parent_path, attr_name = path.split_jdl_path
      klass = api_class_from_path(parent_path)
      if klass.method_defined?(attr_name)
        JABA.error("#{path} attribute defined more than once")
      end
      klass.define_method(attr_name) do |*args, **kwargs, &attr_block|
        $last_call_location = ::Kernel.caller_locations(1, 1)[0]
        @node.handle_attr(attr_name, *args, **kwargs, &attr_block)
      end
      # TODO: automatically make class name from typeid
      attr_type_class = case type
        when :bool
          JABA::AttributeTypeBool
        when :choice
          JABA::AttributeTypeChoice
        when :uuid
          JABA::AttributeTypeUUID
        else
          JABA::AttributeTypeNull
        end
      attr_type = attr_type_class.singleton
      attr_def = def_klass.new(src_loc, attr_name, attr_type)
      AttributeDefinitionAPI.execute(attr_def, &block) if block_given?
      attr_def.post_create
      klass.attr_defs << attr_def
    end
  end
end
