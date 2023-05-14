module JABA
  JDLTopLevelAPI = APIBuilder.define(
    :attr_type,
    :flag,
    :basedir_spec,
    :global_method,
    :method,
    :attr,
    :attr_array,
    :attr_hash,
    :node,
  )
  CommonAPI = APIBuilder.define_module(:title, :note, :example)
  AttributeTypeDefinitionAPI = APIBuilder.define().include(CommonAPI)
  FlagDefinitionAPI = APIBuilder.define(:compatible?, :init_attr_def).include(CommonAPI)
  BasedirSpecDefinitionAPI = APIBuilder.define().include(CommonAPI)
  MethodDefinitionAPI = APIBuilder.define(:on_called).include(CommonAPI)
  NodeDefinitionAPI = APIBuilder.define().include(CommonAPI)

  # Additional attribute type-specific properties are added by attribute types
  AttributeDefinitionAPI = APIBuilder.define(
    :flags,
    :flag_options,
    :value_option,
    :default,
    :validate,
    :validate_key, # Used by hash attribute
    :on_set,
  ).include(CommonAPI)

  @@core_api_blocks = []
  @@current_api_blocks = []

  def self.core_api_blocks = @@core_api_blocks
  def self.current_api_blocks = @@current_api_blocks
  def self.restore_core_api = @@current_api_blocks.clear # Used by unit tests

  def self.define_api(&block)
    @@core_api_blocks << block
  end

  def self.set_test_api_block(&block)
    raise "block required" if !block
    @@current_api_blocks.clear
    @@current_api_blocks.concat(@@core_api_blocks)
    @@current_api_blocks << block
  end

  class JDLBuilder
    def initialize(api_blocks = JABA.core_api_blocks)
      @building_jdl = false
      @definition_lookup = {}
      @path_to_node_def = {}
      @base_api_class = Class.new(BasicObject) do
        undef_method :!, :!=, :==, :equal?, :__id__

        def initialize(node) = @node = node

        def self.set_inspect_name(name) = @inspect_name = name
        def self.inspect = "#<Class:#{@inspect_name}>"

        def method_missing(id, ...)
          $last_call_location = ::Kernel.calling_location
          @node.attr_or_method_not_found_error(id)
        end
      end

      @top_level_api_class = Class.new(@base_api_class)
      @top_level_api_class.set_inspect_name("TopLevelAPI")

      @common_attrs_module = Module.new
      @common_attr_node_def = make_definition(NodeDefinition, nil, "common_attrs", nil) do |d|
        d.set_title("TODO")
        d.set_api_class(@common_attrs_module)
      end

      @common_methods_module = Module.new
      @common_methods_node_def = make_definition(NodeDefinition, nil, "common_methods", nil) do |d|
        d.set_title("TODO")
        d.set_api_class(@common_methods_module)
      end

      @global_methods_module = Module.new
      @global_methods_node_def = make_definition(NodeDefinition, nil, "global_methods", nil) do |d|
        d.set_title("TODO")
        d.set_api_class(@global_methods_module)
      end
      @base_api_class.include(@global_methods_module)

      @path_to_node_def["*"] = @common_attr_node_def
      @top_level_node_def = make_definition(NodeDefinition, nil, "top_level", nil) do |d|
        d.set_title("TODO")
        d.set_api_class(@top_level_api_class)
      end
      @path_to_node_def[nil] = @top_level_node_def

      @building_jdl = true
      api_blocks.each do |b|
        JDLTopLevelAPI.execute(self, &b)
      end
      @building_jdl = false
    end

    def building_jdl? = @building_jdl
    def common_attr_node_def = @common_attr_node_def
    def global_methods_node_def = @global_methods_node_def
    def top_level_node_def = @top_level_node_def
    def top_level_api_class = @top_level_api_class

    def set_attr_type(name, &block)
      name = validate_name(name)
      attr_type_class = JABA.const_get("AttributeType#{name.to_s.capitalize_first}")
      make_definition(attr_type_class, AttributeTypeDefinitionAPI, name, block, lookup_key: :attr_types)
    end

    def set_flag(name, &block)
      name = validate_name(name)
      make_definition(FlagDefinition, FlagDefinitionAPI, name, block)
    end

    def set_basedir_spec(name, &block)
      name = validate_name(name)
      make_definition(BasedirSpecDefinition, BasedirSpecDefinitionAPI, name, block)
    end

    def set_node(path, &block)
      path = validate_path(path)
      if @path_to_node_def.has_key?(path)
        error("Duplicate '#{path}' node registered")
      end

      parent_path, name = split_jdl_path(path)
      parent_def = lookup_node_def(parent_path)

      api_class = Class.new(@top_level_api_class)
      api_class.set_inspect_name(name)
      api_class.include(@common_attrs_module)
      api_class.include(@common_methods_module)

      node_def = make_definition(NodeDefinition, NodeDefinitionAPI, name, block)
      node_def.set_api_class(api_class)

      @path_to_node_def[path] = node_def
      parent_def.node_defs << node_def
      node_def.set_parent_node_def(parent_def)

      parent_def.api_class.define_method(name) do |*args, **kwargs, &node_block|
        $last_call_location = ::Kernel.calling_location
        JABA.context.register_node(node_def, *args, **kwargs, &node_block)
      end
    end

    def set_attr(path, type: :null, &block)
      process_attr(path, AttributeSingleDefinition, type, block)
    end

    def set_attr_array(path, type: :null, &block)
      process_attr(path, AttributeArrayDefinition, type, block)
    end

    def set_attr_hash(path, key_type: :null, type: :null, &block)
      process_attr(path, AttributeHashDefinition, type, block) do |attr_def|
        attr_def.set_key_type(key_type)
      end
    end

    def set_global_method(name, &block)
      name = validate_name(name)
      process_method(@global_methods_node_def, name, name, block)
    end

    def set_method(path, &block)
      path = validate_path(path)
      parent_path, name = split_jdl_path(path)

      node_def = if parent_path == "*"
          @common_methods_node_def
        else
          lookup_node_def(parent_path)
        end
      process_method(node_def, path, name, block)
    end

    def lookup_definition(klass, name, fail_if_not_found: true, attr_def: nil)
      all = lookup_definitions(klass, fail_if_not_found: fail_if_not_found)
      d = all.find { |fd| fd.name == name }
      if d.nil? && fail_if_not_found
        msg = "'#{name.inspect_unquoted}' must be one of #{all.sort_by{|d| d.name}.map { |s| s.name }}"
        if attr_def
          attr_def.definition_error(msg)
        else
          JABA.error(msg)
        end
      end
      d
    end

    def lookup_definitions(klass, fail_if_not_found: true)
      all = @definition_lookup[klass]
      if all.nil? && fail_if_not_found
        JABA.error("No '#{klass}' definition class registered")
      end
      all
    end

    private

    def process_attr(path, def_class, type_id, block)
      path = validate_path(path)
      parent_path, attr_name = split_jdl_path(path)
      node_def = lookup_node_def(parent_path)

      attr_def = make_definition(def_class, AttributeDefinitionAPI, attr_name, block) do |ad|
        attr_type = lookup_definition(:attr_types, type_id, attr_def: ad)
        ad.set_attr_type(attr_type)
        yield ad if block_given?
      end

      if attr_def.has_flag?(:node_option)
        node_def.option_attr_defs << attr_def
      else
        node_def.attr_defs << attr_def
      end

      parent_class = node_def.api_class
      error("api class for '#{path}' node was nil") if parent_class.nil?

      if parent_class.method_defined?(attr_name)
        error("Duplicate '#{path}' attribute registered")
      end
      parent_class.define_method(attr_name) do |*args, **kwargs, &attr_block|
        $last_call_location = ::Kernel.calling_location
        @node.handle_attr(attr_name, *args, **kwargs, &attr_block)
      end

      if type_id == :compound
        # Compound attr interface inherits parent nodes interface so it has read only access to its attrs
        cmp_api = Class.new(parent_class)
        cmp_api.set_inspect_name(attr_name)

        cmp_def = AttributeGroupDefinition.new
        cmp_def.instance_variable_set(:@jdl_builder, self)
        cmp_def.set_api_class(cmp_api)
        cmp_def.set_parent_node_def(node_def)
        attr_def.set_compound_def(cmp_def)
        @path_to_node_def[path] = cmp_def
      end
    end

    def process_method(node_def, path, name, block)
      parent_class = node_def.api_class
      if parent_class.method_defined?(name)
        error("Duplicate '#{path}' method registered")
      end

      meth_def = make_definition(MethodDefinition, MethodDefinitionAPI, name, block)
      node_def.method_defs << meth_def

      parent_class.define_method(name) do |*args, **kwargs, &meth_block|
        $last_call_location = ::Kernel.calling_location
        if meth_def.on_called
          return meth_def.on_called.call(*args, **kwargs, &meth_block)
        else
          node_meth = "jdl_#{name}"
          if @node.respond_to?(node_meth)
            return @node.send(node_meth, *args, **kwargs, &meth_block)
          end
        end
        error("No method handler for #{name.inspect_unquoted} defined")
      end
    end

    def make_definition(klass, api, name, block, lookup_key: nil)
      lookup_key = klass if lookup_key.nil?
      d = klass.new
      d.instance_variable_set(:@jdl_builder, self)
      d.instance_variable_set(:@name, name)
      d.instance_variable_set(:@src_loc, APIBuilder.last_call_location)
      @definition_lookup.push_value(lookup_key, d)
      yield d if block_given?
      api.execute(d, &block) if block
      d.post_create
      d
    end

    def lookup_node_def(path)
      nd = @path_to_node_def[path]
      error("No '#{path}' node registered") if nd.nil?
      nd
    end

    def error(msg) = JABA.error(msg, line: APIBuilder.last_call_location)

    def validate_name(name)
      if !name.is_a?(String) && !name.is_a?(Symbol)
        error("'#{name.inspect_unquoted}' must be a String or a Symbol")
      end
      if name !~ /^[a-zA-Z0-9_]+$/
        error("'#{name}' is in invalid format")
      end
      name
    end

    # Allows eg node_name/node2_name/attr or */attr
    def validate_path(path)
      if !path.is_a?(String) && !path.is_a?(Symbol)
        error("'#{path.inspect_unquoted}' must be a String or a Symbol")
      end
      path = path.to_s # Use strings internally
      if path !~ /^(\*\/)?([a-zA-Z0-9]+_?\/?)+$/ || path !~ /[a-zA-Z0-9]$/
        error("'#{path}' is in invalid format")
      end
      path
    end

    def split_jdl_path(path)
      if path !~ /\//
        [nil, path]
      else
        [path.sub(/\/(\w+)$/, ""), $1]
      end
    end
  end
end
