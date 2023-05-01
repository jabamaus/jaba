module JABA
  JDLTopLevelAPI = APIBuilder.define(
    :attr_type,
    :flag,
    :basedir_spec,
    :method,
    :attr,
    :attr_array,
    :attr_hash,
    :node,
  )
  CommonAPI = APIBuilder.define_module(:title, :note, :example)
  AttributeTypeDefinitionAPI = APIBuilder.define().include(CommonAPI)
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

  @@core_api_blocks = {}
  @@current_api_blocks = []

  def self.core_api_blocks = @@core_api_blocks
  def self.current_api_blocks = @@current_api_blocks
  def self.restore_core_api = @@current_api_blocks.clear # Used by unit tests
  def self.define_api(id, &block)
    @@core_api_blocks[id] = block
  end

  # Set which apis are required. Used as efficiency mechanism for unit tests
  def self.set_api_level(apis, &block)
    @@current_api_blocks.clear
    @@current_api_blocks << @@core_api_blocks[:core] # Core always required
    apis.each do |id|
      if id == :core
        JABA.warn("No need to specify :core api as always included")
      else
        api = @@core_api_blocks[id]
        JABA.error("'#{id}' api undefined") if api.nil?
        @@current_api_blocks << api
      end
    end
    @@current_api_blocks << block if block
  end

  class JDLBuilder
    def initialize
      @definition_lookup = {}
      @path_to_class = {}
      @base_api_class = Class.new(BasicObject) do
        undef_method :!, :!=, :==, :equal?, :__id__
        def self.singleton = @instance ||= new
        def self.attr_defs = @attr_defs ||= []
        def self.each_attr_def(&block) = attr_defs.each(&block)

        def __internal_set_node(n); @node = n; self; end

        def method_missing(id, ...)
          $last_call_location = ::Kernel.calling_location
          @node.attr_not_found_error(id, errline: $last_call_location)
        end
      end
      # attrs get registered into top_level_api_class_base and methods and nodes get registered into top_level_api_class
      # Nodes inherit from top_level_api_class_base so facilitate read only access to attributes but no access to methods
      @top_level_api_class_base = Class.new(@base_api_class)
      @top_level_api_class = Class.new(@top_level_api_class_base)
      @common_attrs_module = Module.new do
        def self.attr_defs = @attr_defs ||= []
      end
    end

    def top_level_api_class = @top_level_api_class
    def top_level_api_class_base = @top_level_api_class_base

    def class_from_path(path, fail_if_not_found: true)
      klass = @path_to_class[path]
      error("class not registered for '#{path}' path") if klass.nil? && fail_if_not_found
      klass
    end

    def set_attr_type(name, &block)
      attr_type_class = JABA.const_get("AttributeType#{name.to_s.capitalize_first}")
      at = make_definition(attr_type_class, name, lookup_key: :attr_types)
      AttributeTypeDefinitionAPI.execute(at, &block) if block
      at.post_create
    end

    def set_flag(name, &block)
      fd = make_definition(FlagDefinition, name)
      FlagDefinitionAPI.execute(fd, &block) if block
    end

    def set_basedir_spec(name, &block)
      d = make_definition(BasedirSpecDefinition, name)
      BasedirSpecDefinitionAPI.execute(d, &block) if block
    end

    # TODO: disallow nesting nodes
    def set_node(path, &block)
      path = validate_path(path)
      parent_path, name = split_jdl_path(path)

      node_def = make_definition(NodeDefinition, name)
      NodeDefinitionAPI.execute(node_def, &block) if block
      node_def.post_create

      node_class = get_or_make_class(path, superklass: @top_level_api_class_base, what: :node)
      node_class.include(@common_attrs_module)
      common_attrs_module = @common_attrs_module
      node_class.define_singleton_method :each_attr_def do |&block|
        attr_defs.each(&block)
        common_attrs_module.attr_defs.each(&block)
      end

      parent_class = get_or_make_class(parent_path, what: :node)
      parent_class.define_method(name) do |*args, **kwargs, &node_block|
        $last_call_location = ::Kernel.calling_location
        JABA.context.register_node(node_class, *args, **kwargs, &node_block)
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

    def set_method(path, &block)
      path = validate_path(path)
      parent_path, name = split_jdl_path(path)
      
      meth_def = make_definition(MethodDefinition, name)
      MethodDefinitionAPI.execute(meth_def, &block) if block
      meth_def.post_create
      
      parent_class = get_or_make_class(parent_path, what: :method)
      parent_class.define_method(name) do |*args, **kwargs|
        $last_call_location = ::Kernel.calling_location
        instance_exec(*args, **kwargs, node: @node, &meth_def.on_called)
      end
    end

    def lookup_definition(klass, name, fail_if_not_found: true, attr_def: nil)
      all = @definition_lookup[klass]
      if all.nil?
        JABA.error("No '#{klass}' definition class registered") if fail_if_not_found
        return nil
      end
      d = all.find { |fd| fd.name == name }
      if d.nil? && fail_if_not_found
        msg = "'#{name.inspect_unquoted}' must be one of #{all.map { |s| s.name }}"
        if attr_def
          attr_def.definition_error(msg)
        else
          JABA.error(msg)
        end
      end
      d
    end

    def each_definition(klass, &block)
      all = @definition_lookup[klass]
      if all.nil?
        JABA.error("No '#{klass}' definition class registered") if fail_if_not_found
        return nil
      end
      all.each(&block)
    end

    private

    def process_attr(path, def_class, type_id, block)
      path = validate_path(path)
      parent_path, attr_name = split_jdl_path(path)
      
      attr_def = make_definition(def_class, attr_name)
      attr_type = lookup_definition(:attr_types, type_id, attr_def: attr_def)
      attr_def.set_attr_type(attr_type)
      attr_type.init_attr_def(attr_def)
      yield attr_def if block_given?
      AttributeDefinitionAPI.execute(attr_def, &block) if block
      attr_def.post_create
      
      parent_class = get_or_make_class(parent_path, what: :attribute)
      if parent_class.method_defined?(attr_name)
        error("Duplicate '#{path}' attribute registered")
      end
      parent_class.define_method(attr_name) do |*args, **kwargs, &attr_block|
        $last_call_location = ::Kernel.calling_location
        @node.handle_attr(attr_name, *args, **kwargs, &attr_block)
      end
  
      if type_id == :compound
        # Compound attr interface inherits parent nodes interface so it has read only access to its attrs
        attr_def.set_compound_api(get_or_make_class(path, superklass: parent_class, what: :attribute))
      end

      parent_class.attr_defs << attr_def
    end

    def get_or_make_class(path, superklass: nil, what:)
      if path.nil?
        case what
        when :attribute
          return @top_level_api_class_base
        else
          return @top_level_api_class
        end
      elsif path == "*"
        case what
        when :method
          return @base_api_class
        when :attribute
          return @common_attrs_module
        else
          JABA.error("'#{what}' not handled")
        end
      end
      klass = class_from_path(path, fail_if_not_found: superklass.nil?)
      if superklass
        error("Duplicate path '#{path}' registered.") if klass
        klass = Class.new(superklass)
        @path_to_class[path] = klass
        klass
      end
      return klass
    end

    def make_definition(klass, name, *args, lookup_key: nil)
      lookup_key = klass if lookup_key.nil?
      d = klass.new(APIBuilder.last_call_location, name, *args)
      d.instance_variable_set(:@jdl_builder, self)
      @definition_lookup.push_value(lookup_key, d)
      d
    end

    def error(msg) = JABA.error(msg, line: APIBuilder.last_call_location)

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
