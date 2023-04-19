module JDL
  CommonAPI = APIBuilder.define_module(:title, :note, :example)
  FlagDefinitionAPI = APIBuilder.define(:compatible?).include(CommonAPI)
  BasedirSpecDefinitionAPI = APIBuilder.define().include(CommonAPI)
  MethodDefinitionAPI = APIBuilder.define(:on_called).include(CommonAPI)
  NodeDefinitionAPI = APIBuilder.define().include(CommonAPI)
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

  # BaseAPI is the blankest possible slate. The purpose of BaseAPI and its dynamically
  # created subclasses is to define what is allowed to be called at any given level when
  # creating end user definitions.
  #
  class BaseAPI < BasicObject
    undef_method :!, :!=, :==, :equal?, :__id__
    def self.singleton = @instance ||= self.new
    def self.attr_defs = @attr_defs ||= []
    def self.each_attr_def(&block)
      CommonAttrsAPI.attr_defs.each(&block)
      attr_defs.each(&block)
    end
    def __internal_set_node(n)
      @node = n
      self
    end
    def method_missing(id, ...)
      @node.attr_not_found_error(id)
    end
  end

  module CommonAttrsAPI
    def self.attr_defs = @attr_defs ||= []
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
    validate_path(path)
    node_api_klass = api_class_from_path(path, create: true)
    node_api_klass.include(CommonAttrsAPI)
    node_api_klass.class_eval do
      def self.get_attr_defs = self.attr_defs + CommonAttrs.attr_defs
    end
    parent_path, item = split_jdl_path(path)
    parent_klass = api_class_from_path(parent_path)
    node_def = JABA::NodeDefinition.new(calling_location, name)
    NodeDefinitionAPI.execute(node_def, &block) if block_given?
    node_def.post_create
    parent_klass.define_method(item) do |*args, **kwargs, &node_block|
      $last_call_location = ::Kernel.calling_location
      JABA.context.register_node(node_api_klass, *args, **kwargs, &node_block)
    end
  end

  def self.attr(path, type: nil, &block)
    process_attr(calling_location, path, JABA::AttributeSingleDefinition, type, &block)
  end

  def self.attr_array(path, type: nil, &block)
    process_attr(calling_location, path, JABA::AttributeArrayDefinition, type, &block)
  end

  def self.attr_hash(path, type: nil, &block)
    process_attr(calling_location, path, JABA::AttributeHashDefinition, type, &block)
  end

  # Used during testing to prevent polluting the TopLevelAPI namespace
  def self.undefine_attr(path)
    parent_path, attr_name = split_jdl_path(path)
    parent_klass = api_class_from_path(parent_path)
    if !parent_klass.method_defined?(attr_name)
      JABA.error("Cannot undefine #{path} - not defined")
    end
    parent_klass.remove_method(attr_name)
    parent_klass.attr_defs.delete_if{|ad| ad.name == attr_name}
  end

  def self.method(path, &block)
    validate_path(path)
    parent_path, name = split_jdl_path(path)
    klass = api_class_from_path(parent_path, method: true)
    meth_def = JABA::MethodDefinition.new(calling_location, name)
    MethodDefinitionAPI.execute(meth_def, &block) if block_given?
    meth_def.post_create
    klass.define_method(name) do |*args, **kwargs|
      $last_call_location = ::Kernel.calling_location
      meth_def.on_called&.call(*args, **kwargs, node: @node)
    end
  end

  private

  # Allows eg node_name|node2_name|attr or *|attr
  def self.validate_path(path)
    if path !~ /^(\*\|)?([a-zA-Z0-9]+_?\|?)+$/ || path !~ /[a-zA-Z0-9]$/
      JABA.error("'#{path}' is in invalid format")
    end
  end

  def self.split_jdl_path(path)
    if path !~ /\|/
      [nil, path]
    else
      [path.sub(/\|(\w+)$/, ""), $1]
    end
  end

  def self.api_class_from_path(path, superklass: BaseAPI, create: false, method: false)
    if path.nil?
      return TopLevelAPI
    elsif path == '*'
      if method
        return BaseAPI
      else
        return CommonAttrsAPI
      end
    end
    name = "#{path.split("|").map { |p| p.capitalize_first }.join}API"
    if create
      JDL.const_set(name, Class.new(superklass))
    elsif JDL.const_defined?(name)
      JDL.const_get(name)
    else
      JABA.error("#{name} constant not defined")
    end
  end

  def self.process_attr(src_loc, path, def_klass, type, &block)
    validate_path(path)
    parent_path, attr_name = split_jdl_path(path)
    parent_klass = api_class_from_path(parent_path)
    if parent_klass.method_defined?(attr_name)
      JABA.error("#{path} attribute defined more than once")
    end
    parent_klass.define_method(attr_name) do |*args, **kwargs, &attr_block|
      $last_call_location = ::Kernel.calling_location
      @node.handle_attr(attr_name, *args, **kwargs, &attr_block)
    end
    type = "Null" if type.nil?
    attr_type_class = JABA.const_get("AttributeType#{type.to_s.capitalize_first}")
    attr_type = attr_type_class.singleton
    attr_def = def_klass.new(src_loc, attr_name, attr_type)
    attr_type.init_attr_def(attr_def)
    if type == :compound
      # Compound attr interface inherits parent nodes interface so it has read only access to its attrs
      attr_def.set_compound_api(api_class_from_path(path, superklass: parent_klass, create: true))
    end

    AttributeDefinitionAPI.execute(attr_def, &block) if block_given?
    attr_def.post_create
    parent_klass.attr_defs << attr_def
  end
end
