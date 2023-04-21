module JDL
  JDLTopLevelAPI = APIBuilder.define(
    :flag,
    :basedir_spec,
    :method,
    :attr,
    :attr_array,
    :attr_hash,
    :node,
  )
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

  def self.current_jdl = @@current_jdl

  def self.define(private: false, &block)
    @@current_jdl = if private
      JDLBuilder.new
    else
      @@core_jdl ||= JDLBuilder.new
    end
    JDLTopLevelAPI.execute(@@current_jdl, &block)
  end

  class JDLBuilder
    def initialize
      @path_to_class = {}
      @base_api_class = Class.new(BasicObject) do
        undef_method :!, :!=, :==, :equal?, :__id__
        def self.singleton = @instance ||= new
        def self.attr_defs = @attr_defs ||= []
        def self.each_attr_def(&block) = attr_defs.each(&block)
    
        def __internal_set_node(n)
          @node = n
          self
        end
    
        def method_missing(id, ...) = @node.attr_not_found_error(id)
      end
      @toplevel_api_class = Class.new(@base_api_class)
      @common_attrs_module = Module.new do
        def self.attr_defs = @attr_defs ||= []
      end
    end

    def top_level_api_class = @toplevel_api_class
    
    def class_from_path(path)
      klass = @path_to_class[path]
      JABA.error("class not registered for '#{path}' path") if klass.nil?
      klass
    end

    def set_flag(name, &block)
      fd = JABA::FlagDefinition.new(calling_location, name)
      FlagDefinitionAPI.execute(fd, &block) if block_given?
    end

    def set_basedir_spec(name, &block)
      d = JABA::BasedirSpecDefinition.new(calling_location, name)
      BasedirSpecDefinitionAPI.execute(d, &block) if block_given?
    end

    def set_node(path, &block)
      validate_path(path)
      node_api_klass = api_class_from_path(path, create: true)
      node_api_klass.include(@common_attrs_module)
      common_attrs_module = @common_attrs_module
      node_api_klass.define_singleton_method :each_attr_def do |&block|
        attr_defs.each(&block)
        common_attrs_module.attr_defs.each(&block)
      end
      parent_path, name = split_jdl_path(path)
      parent_klass = api_class_from_path(parent_path)
      node_def = JABA::NodeDefinition.new(calling_location, name)
      NodeDefinitionAPI.execute(node_def, &block) if block_given?
      node_def.post_create
      parent_klass.define_method(name) do |*args, **kwargs, &node_block|
        $last_call_location = ::Kernel.calling_location
        JABA.context.register_node(node_api_klass, *args, **kwargs, &node_block)
      end
    end

    def set_attr(path, type: nil, &block)
      process_attr(calling_location, path, JABA::AttributeSingleDefinition, type, &block)
    end

    def set_attr_array(path, type: nil, &block)
      process_attr(calling_location, path, JABA::AttributeArrayDefinition, type, &block)
    end

    def set_attr_hash(path, type: nil, &block)
      process_attr(calling_location, path, JABA::AttributeHashDefinition, type, &block)
    end

    def set_method(path, &block)
      validate_path(path)
      parent_path, name = split_jdl_path(path)
      klass = api_class_from_path(parent_path, method: true)
      meth_def = JABA::MethodDefinition.new(calling_location, name)
      MethodDefinitionAPI.execute(meth_def, &block) if block_given?
      meth_def.post_create
      klass.define_method(name) do |*args, **kwargs|
        $last_call_location = ::Kernel.calling_location
        instance_exec(*args, **kwargs, node: @node, &meth_def.on_called)
      end
    end

    private

    # Allows eg node_name|node2_name|attr or *|attr
    def validate_path(path)
      if path !~ /^(\*\|)?([a-zA-Z0-9]+_?\|?)+$/ || path !~ /[a-zA-Z0-9]$/
        JABA.error("'#{path}' is in invalid format")
      end
    end

    def split_jdl_path(path)
      if path !~ /\|/
        [nil, path]
      else
        [path.sub(/\|(\w+)$/, ""), $1]
      end
    end

    def api_class_from_path(path, superklass: @base_api_class, create: false, method: false)
      if path.nil?
        return @toplevel_api_class
      elsif path == "*"
        if method
          return @base_api_class
        else
          return @common_attrs_module
        end
      end
      if create
        klass = Class.new(superklass)
        if @path_to_class.has_key?(path)
          JABA.error("Duplicate path '#{path}' encountered")
        end
        @path_to_class[path] = klass
        klass
      else
        class_from_path(path)
      end
    end

    def process_attr(src_loc, path, def_klass, type, &block)
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
end
