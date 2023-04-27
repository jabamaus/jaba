module JABA
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

  @@core_api_block = nil
  @@current_api_block = nil

  def self.core_api_block = @@core_api_block
  def self.current_api_block = @@current_api_block
  def self.restore_core_api = @@current_api_block = @@core_api_block # Used by unit tests
  def self.define_api(&block)
    if @@core_api_block.nil?
      @@core_api_block = block
    end
    @@current_api_block = block
  end

  class JDLBuilder
    def initialize
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

      # register some always available methods
      JDLTopLevelAPI.execute(self) do
        method "*|available" do
          title "Array of attributes/methods available in current context"
          on_called do |str, node:| node.available end
        end

        method "*|print" do
          title "Prints a non-newline terminated string to stdout"
          on_called do |str| Kernel.print(str) end
        end

        method "*|puts" do
          title "Prints a newline terminated string to stdout"
          on_called do |str| Kernel.puts(str) end
        end

        method "*|fail" do
          title "Raise an error"
          note "Stops execution"
          on_called do |msg| JABA.error(msg, line: $last_call_location) end
        end
      end
    end

    def top_level_api_class = @top_level_api_class
    def top_level_api_class_base = @top_level_api_class_base

    def class_from_path(path, fail_if_not_found: true)
      klass = @path_to_class[path]
      error("class not registered for '#{path}' path") if klass.nil? && fail_if_not_found
      klass
    end

    def set_flag(name, &block)
      fd = FlagDefinition.new(APIBuilder.last_call_location, name)
      FlagDefinitionAPI.execute(fd, &block) if block_given?
    end

    def set_basedir_spec(name, &block)
      d = BasedirSpecDefinition.new(APIBuilder.last_call_location, name)
      BasedirSpecDefinitionAPI.execute(d, &block) if block_given?
    end

    # TODO: disallow nesting nodes
    def set_node(path, &block)
      path = validate_path(path)
      node_class = get_or_make_class(path, superklass: @top_level_api_class_base, what: :node)
      node_class.include(@common_attrs_module)
      common_attrs_module = @common_attrs_module
      node_class.define_singleton_method :each_attr_def do |&block|
        attr_defs.each(&block)
        common_attrs_module.attr_defs.each(&block)
      end
      parent_path, name = split_jdl_path(path)
      parent_class = get_or_make_class(parent_path, what: :node)
      node_def = NodeDefinition.new(APIBuilder.last_call_location, name)
      NodeDefinitionAPI.execute(node_def, &block) if block_given?
      node_def.post_create
      parent_class.define_method(name) do |*args, **kwargs, &node_block|
        $last_call_location = ::Kernel.calling_location
        JABA.context.register_node(node_class, *args, **kwargs, &node_block)
      end
    end

    def set_attr(path, type: nil, &block)
      process_attr(path, AttributeSingleDefinition, type, block)
    end

    def set_attr_array(path, type: nil, &block)
      process_attr(path, AttributeArrayDefinition, type, block)
    end

    def set_attr_hash(path, key_type: nil, type: nil, &block)
      process_attr(path, AttributeHashDefinition, type, block) do |attr_def|
        attr_def.set_key_type(key_type)
      end
    end

    def set_method(path, &block)
      path = validate_path(path)
      parent_path, name = split_jdl_path(path)
      parent_class = get_or_make_class(parent_path, what: :method)
      meth_def = MethodDefinition.new(APIBuilder.last_call_location, name)
      MethodDefinitionAPI.execute(meth_def, &block) if block_given?
      meth_def.post_create
      parent_class.define_method(name) do |*args, **kwargs|
        $last_call_location = ::Kernel.calling_location
        instance_exec(*args, **kwargs, node: @node, &meth_def.on_called)
      end
    end

    private

    def process_attr(path, def_class, type, block)
      path = validate_path(path)
      parent_path, attr_name = split_jdl_path(path)
      parent_class = get_or_make_class(parent_path, what: :attribute)
      if parent_class.method_defined?(attr_name)
        error("Duplicate '#{path}' attribute registered")
      end
      parent_class.define_method(attr_name) do |*args, **kwargs, &attr_block|
        $last_call_location = ::Kernel.calling_location
        @node.handle_attr(attr_name, *args, **kwargs, &attr_block)
      end
      type = "Null" if type.nil?
      attr_type_class = JABA.const_get("AttributeType#{type.to_s.capitalize_first}")
      attr_type = attr_type_class.singleton
      attr_def = def_class.new(APIBuilder.last_call_location, attr_name, attr_type)
      attr_type.init_attr_def(attr_def)
      if type == :compound
        # Compound attr interface inherits parent nodes interface so it has read only access to its attrs
        attr_def.set_compound_api(get_or_make_class(path, superklass: parent_class, what: :attribute))
      end
      yield attr_def if block_given?

      AttributeDefinitionAPI.execute(attr_def, &block) if block
      attr_def.post_create
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

    def error(msg) = JABA.error(msg, line: APIBuilder.last_call_location)

    # Allows eg node_name|node2_name|attr or *|attr
    def validate_path(path)
      if !path.is_a?(String) && !path.is_a?(Symbol)
        error("'#{path.inspect_unquoted}' must be a String or a Symbol")
      end
      path = path.to_s # Use strings internally
      if path !~ /^(\*\|)?([a-zA-Z0-9]+_?\|?)+$/ || path !~ /[a-zA-Z0-9]$/
        error("'#{path}' is in invalid format")
      end
      path
    end

    def split_jdl_path(path)
      if path !~ /\|/
        [nil, path]
      else
        [path.sub(/\|(\w+)$/, ""), $1]
      end
    end
  end
end
