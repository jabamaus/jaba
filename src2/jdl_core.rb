module JDL
  CommonAPI = APIBuilder.define_module(:title, :note, :example)
  FlagDefinitionAPI = APIBuilder.define(:compatible?).include(CommonAPI)
  BasedirSpecDefinitionAPI = APIBuilder.define().include(CommonAPI)
  AttributeDefinitionAPI = APIBuilder.define(
    :flags,
    :flag_options,
    :value_option,
    :default,
    :validate,
    :validate_key, # Used by hash attribute
    :items, # Used by choice attribute
    :basedir_spec, # Used by path attributes
  ).include(CommonAPI)
  MethodDefinitionAPI = APIBuilder.define(:on_called).include(CommonAPI)

  # BaseAPI is the blankest possible slate
  class BaseAPI < BasicObject
    undef_method :!, :!=, :==, :equal?, :__id__
    def self.singleton = @instance ||= self.new
    def self.attr_defs = @attr_defs ||= []
    def self.each_attr_def(&block)
      klass = self
      while (klass != BasicObject)
        klass.attr_defs.each(&block)
        klass = klass.superclass
      end
    end
    def __internal_set_node(n) = @node = n
  end

  class TopLevelAPI < BaseAPI; end

  def self.flag(name, &block)
    fd = JABA::FlagDefinition.new(calling_location, name)
    FlagDefinitionAPI.execute(fd, &block) if block_given?
  end

  def self.basedir_spec(name, &block)
    d = JABA::BasedirSpecDefinition.new(calling_location, name)
    BasedirSpecDefinitionAPI.execute(d, &block) if block_given?
  end

  def self.node(path, &block)
    node_api_klass = api_class_from_path(path, create: true)
    parent_path, item = split_jdl_path(path)
    parent_klass = api_class_from_path(parent_path)
    parent_klass.define_method(item) do |*args, **kwargs, &node_block|
      $last_call_location = ::Kernel.calling_location
      JABA.context.register_node(node_api_klass, *args, **kwargs, &node_block)
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

  def self.method(path, &block)
    src_loc = calling_location
    parent_path, name = split_jdl_path(path)
    klass = api_class_from_path(parent_path)
    meth_def = JABA::MethodDefinition.new(src_loc, name)
    MethodDefinitionAPI.execute(meth_def, &block) if block_given?
    meth_def.post_create
    klass.define_method(name) do |*args, **kwargs|
      $last_call_location = ::Kernel.calling_location
      meth_def.on_called&.call(*args, **kwargs)
    end
  end

  private

  def self.split_jdl_path(path)
    if path !~ /\|/
      [nil, path]
    else
      [path.sub(/\|(\w+)$/, ""), $1]
    end
  end

  def self.api_class_from_path(path, create: false)
    if path.nil?
      return TopLevelAPI
    elsif path == '*'
      return BaseAPI
    end
    name = "#{path.split("|").map { |p| p.capitalize_first }.join}API"
    if create
      JDL.const_set(name, Class.new(BaseAPI))
    else
      JDL.const_get(name)
    end
  end

  def self.process_attr(src_loc, paths, def_klass, type, &block)
    paths.each do |path|
      parent_path, attr_name = split_jdl_path(path)
      klass = api_class_from_path(parent_path)
      if klass.method_defined?(attr_name)
        JABA.error("#{path} attribute defined more than once")
      end
      klass.define_method(attr_name) do |*args, **kwargs, &attr_block|
        $last_call_location = ::Kernel.calling_location
        @node.handle_attr(attr_name, *args, **kwargs, &attr_block)
      end
      type = "Null" if type.nil?
      attr_type_class = JABA.const_get("AttributeType#{type.to_s.capitalize_first}")
      attr_type = attr_type_class.singleton
      attr_def = def_klass.new(src_loc, attr_name, attr_type)
      AttributeDefinitionAPI.execute(attr_def, &block) if block_given?
      attr_def.post_create
      klass.attr_defs << attr_def
    end
  end
end
