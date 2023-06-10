module JABA
  @@core_api_blocks = []
  @@current_api_blocks = []

  def self.core_api_blocks = @@core_api_blocks
  def self.current_api_blocks = @@current_api_blocks
  def self.restore_core_api = @@current_api_blocks.clear # Used by unit tests

  def self.define_jdl(&block)
    @@core_api_blocks << block
  end

  def self.set_test_api_block(&block)
    raise "block required" if !block
    @@current_api_blocks.clear
    @@current_api_blocks.concat(@@core_api_blocks)
    @@current_api_blocks << block
  end

  class JDLBuilder
    TopLevelAPI = APIBuilder.define(
      :global_method,
      :method,
      :attr,
      :node,
      :translator,
    )

    def initialize(api_blocks = JABA.core_api_blocks)
      @building_jdl = false
      @path_to_node_def = {}
      @translator_lookup = {}
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
      @common_attr_node_def = make_definition(NodeDef, "common_attrs", nil) do |d|
        d.set_title("TODO")
        d.set_api_class(@common_attrs_module)
      end

      @common_methods_module = Module.new
      @common_methods_node_def = make_definition(NodeDef, "common_methods", nil) do |d|
        d.set_title("TODO")
        d.set_api_class(@common_methods_module)
      end

      @global_methods_module = Module.new
      @global_methods_node_def = make_definition(NodeDef, "global_methods", nil) do |d|
        d.set_title("TODO")
        d.set_api_class(@global_methods_module)
      end
      @base_api_class.include(@global_methods_module)

      @path_to_node_def["*"] = @common_attr_node_def
      @top_level_node_def = make_definition(NodeDef, "top_level", nil) do |d|
        d.set_title("TODO")
        d.set_api_class(@top_level_api_class)
      end
      @path_to_node_def[nil] = @top_level_node_def

      @building_jdl = true
      api_blocks.each do |b|
        TopLevelAPI.execute(self, &b)
      end
      @building_jdl = false
      @path_to_node_def.each do |path, node_def|
        node_def.attr_defs.sort_by! { |ad| ad.name }
        node_def.method_defs.sort_by! { |ad| ad.name }
      end
    end

    def building_jdl? = @building_jdl
    def common_attr_node_def = @common_attr_node_def
    def global_methods_node_def = @global_methods_node_def
    def top_level_node_def = @top_level_node_def

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

      node_def = make_definition(NodeDef, name, block)
      node_def.set_api_class(api_class)

      @path_to_node_def[path] = node_def
      parent_def.node_defs << node_def
      node_def.set_parent_node_def(parent_def)

      parent_def.api_class.define_method(name) do |*args, **kwargs, &node_block|
        $last_call_location = ::Kernel.calling_location
        JABA.context.register_node(node_def, *args, **kwargs, &node_block)
      end
    end

    def set_attr(path, variant: :single, type: :null, &block)
      def_class = case variant
      when :single
        AttributeSingleDef
      when :array
        AttributeArrayDef
      when :hash
        AttributeHashDef
      else
        error("Invalid attribute variant '#{variant.inspect_unquoted}'")
      end

      path = validate_path(path)
      parent_path, attr_name = split_jdl_path(path)
      node_def = lookup_node_def(parent_path)

      attr_def = make_definition(def_class, attr_name, block) do |ad|
        ad.set_attr_type(type)
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
        @node.jdl_process_attr(attr_name, *args, __call_loc: $last_call_location, **kwargs, &attr_block)
      end
      case type
      when :bool
        parent_class.define_method("#{attr_name}?") do |*args, **kwargs, &attr_block|
          $last_call_location = ::Kernel.calling_location
          if !args.empty? || !kwargs.empty? || attr_block
            JABA.error("'#{attr_name}?' is a read only accessor and does not accept arguments", line: $last_call_location)
          end
          @node.jdl_process_attr(attr_name, *args, __call_loc: $last_call_location, **kwargs, &attr_block)
        end
      when :compound
        # Compound attr interface inherits parent nodes interface so it has read only access to its attrs
        cmp_api = Class.new(parent_class)
        cmp_api.set_inspect_name(attr_name)

        cmp_def = AttributeGroupDef.new
        cmp_def.instance_variable_set(:@jdl_builder, self)
        cmp_def.set_api_class(cmp_api)
        cmp_def.set_parent_node_def(node_def)
        attr_def.set_compound_def(cmp_def)
        @path_to_node_def[path] = cmp_def
      end
    end

    def set_global_method(name, &block)
      name = validate_name(name, regex: /^[a-zA-Z0-9_]+(\?)?$/)
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

    # TODO: remove
    def set_translator(id, &block)
      @translator_lookup[id] = block
    end

    def lookup_translator(id, fail_if_not_found: true)
      t = @translator_lookup[id]
      JABA.error("'#{id.inspect_unquoted}' translator not found") if t.nil? && fail_if_not_found
      t
    end

    private

    def process_method(node_def, path, name, block)
      parent_class = node_def.api_class
      if parent_class.method_defined?(name)
        error("Duplicate '#{path}' method registered")
      end

      meth_def = make_definition(MethodDef, name, block)
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
        JABA.error("No method handler for #{name.inspect_unquoted} defined")
      end
    end

    def make_definition(klass, name, block)
      d = klass.new
      d.instance_variable_set(:@jdl_builder, self)
      d.instance_variable_set(:@name, name)
      d.instance_variable_set(:@src_loc, APIBuilder.last_call_location)
      yield d if block_given?
      klass.const_get("API").execute(d, &block) if block
      d.post_create
      d
    end

    def lookup_node_def(path)
      nd = @path_to_node_def[path]
      error("No '#{path}' node registered") if nd.nil?
      nd
    end

    def error(msg) = JABA.error(msg, line: APIBuilder.last_call_location)

    def validate_name(name, regex: /^[a-zA-Z0-9_]+$/)
      if !name.is_a?(String) && !name.is_a?(Symbol)
        error("'#{name.inspect_unquoted}' must be a String or a Symbol")
      end
      if name !~ regex
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
        [path.sub(/\/([^\/]+)$/, ""), $1]
      end
    end
  end

  class JDLDefinition
    API = APIBuilder.define_module(:title, :note, :example)

    def initialize
      @jdl_builder = nil # set by JDLBuilder
      @src_loc = nil # Set by JDLBuilder
      @name = nil # Set by JDLBuilder
      @title = nil
      @notes = []
      @examples = []
    end

    def jdl_builder = @jdl_builder
    def src_loc = @src_loc
    def name = @name
    def to_s = @name
    def describe = "'#{name.inspect_unquoted}'"

    def set_title(t) = @title = t
    def title = @title
    def set_note(n) = @notes << n
    def notes = @notes
    def set_example(e) = @examples << e
    def examples = @examples

    def post_create
      @src_loc.freeze
      @name.freeze
      __check(:@title) if !JABA.running_tests?
      @title.freeze
      @notes.freeze
      @examples.freeze
    end

    def __check(var)
      definition_error("var must be specified as a symbol") if !var.symbol?
      if instance_variable_get(var).nil?
        definition_error("#{describe} requires '#{var.to_s.delete_prefix("@")}' to be specified")
      end
    end

    def definition_error(msg)
      line = @jdl_builder.building_jdl? ? APIBuilder.last_call_location : src_loc
      JABA.error("#{describe} invalid - #{msg}", line: line)
    end

    def definition_warn(msg)
      line = @jdl_builder.building_jdl? ? APIBuilder.last_call_location : src_loc
      JABA.warn(msg, line: line)
    end
  end

  class AttributeGroupDef < JDLDefinition
    def initialize
      super()
      @api_class = nil
      @attr_defs = []
      @method_defs = []
      @option_attr_defs = []
      @parent_node_def = nil
    end

    def set_api_class(c) = @api_class = c
    def api_class = @api_class
    def attr_defs = @attr_defs
    def method_defs = @method_defs
    def option_attr_defs = @option_attr_defs
    def set_parent_node_def(nd) = @parent_node_def = nd
    def parent_node_def = @parent_node_def
  end

  class NodeDef < AttributeGroupDef
    API = APIBuilder.define().include(JDLDefinition::API)

    def initialize
      super()
      @child_node_defs = []
    end

    def node_defs = @child_node_defs
  end

  class MethodDef < JDLDefinition
    API = APIBuilder.define(:on_called).include(JDLDefinition::API)
    def initialize
      super()
      @on_called = nil
    end

    # on_called is optional
    def set_on_called(&block) = @on_called = block
    def on_called = @on_called
  end

  class AttributeBaseDef < JDLDefinition

    # Additional attribute type-specific properties are added by attribute types
    API = APIBuilder.define_module(
      :flags,
      :flag_options,
      :value_option,
      :default,
      :validate,
      :on_set,
    ).include(JDLDefinition::API)

    def initialize(variant)
      super()
      @variant = variant
      @attr_type = nil
      @flags = []
      @flag_options = []
      @value_options = []
      @default = nil
      @default_is_block = false
      @default_set = false
      @on_validate = nil
      @on_set = nil
      @compound_def = nil # used by compound attribute
    end

    def set_attr_type(type_id)
      @attr_type = Context.lookup_attr_type(type_id, fail_if_not_found: false)
      if @attr_type.nil?
        definition_error("'#{type_id.inspect_unquoted}' must be one of #{Context.all_attr_types.map{|af| af.name}}")
      end
      @attr_type.init_attr_def(self)
    end

    def post_create
      super
      @default.freeze
      @flags.freeze
      @flag_options.freeze
      __check(:@attr_type)
      @attr_type.post_create_attr_def(self)
    end

    def describe = "'#{@name.inspect_unquoted}' attribute"
    def variant = @variant
    def single? = @variant == :single
    def array? = @variant == :array
    def hash? = @variant == :hash
    def compound? = type_id == :compound
    def attr_type = @attr_type
    def type_id = @attr_type.name

    def flags = @flags

    def set_flags(*flags)
      flags.flatten.each do |f|
        fd = Context.lookup_attr_flag(f, fail_if_not_found: false)
        if fd.nil?
          definition_error("'#{f.inspect_unquoted}' must be one of #{Context.all_attr_flags.map{|af| af.name}}")
        end
        fd.on_compatible&.call(self)
        fd.on_init_attr_def&.call(self)
        @flags << f
      end
    end

    # TODO: check flag is valid
    def has_flag?(flag) = @flags.include?(flag)
    def flag_options = @flag_options

    def set_flag_options(*fo)
      fo.each do |o|
        if @flag_options.include?(o)
          definition_warn("Duplicate flag option '#{o.inspect_unquoted}' specified")
        else
          @flag_options << o
        end
      end
    end

    def has_flag_option?(fo) = @flag_options.include?(fo)

    def set_validate(&block) = @on_validate = block
    def on_validate = @on_validate
    def set_on_set(&block) = @on_set = block
    def on_set = @on_set

    ValueOption = Data.define(:name, :required, :items)

    def set_value_option(name, required: false, items: [])
      if !name.symbol?
        definition_error("In #{describe} value_option id must be specified as a symbol, eg :option")
      end
      @value_options << ValueOption.new(name, required, items)
    end

    def value_option(name)
      if @value_options.empty?
        definition_error("Invalid value option '#{name.inspect_unquoted}' - no options defined in #{describe}")
      end
      vo = @value_options.find { |v| v.name == name }
      if !vo
        definition_error("Invalid value option '#{name.inspect_unquoted}'. Valid #{describe} options: #{@value_options.map { |v| v.name }}")
      end
      vo
    end

    def default = @default
    def default_is_block? = @default_is_block
    def default_set? = @default_set

    def set_default(val = nil, &block)
      @default_set = true
      if block_given?
        @default = block
        @default_is_block = true
      else
        @default = val
      end
    end

    def set_compound_def(d) = @compound_def = d
    def compound_def = @compound_def

    def validate_value(new_val); end # Override
  end

  class AttributeSingleDef < AttributeBaseDef
    API = APIBuilder.define().include(AttributeBaseDef::API)
    
    def initialize
      super(:single)
    end

    def post_create
      # If default not specified by the user (single value attributes only), fall back to default for the attribute
      # type, if there is one eg a string would be ''. Skip if the attribute is flagged as :required, in which case
      # the user must supply the value in definitions.
      #
      if !default_set? && !attr_type.default.nil? && !has_flag?(:required)
        set_default(attr_type.default)
      end
      super
    end

    def validate_value(val)
      if val.is_a?(Enumerable)
        yield "must be a single value not a '#{val.class}'"
      end
    end

    def set_default(val = nil, &block)
      super
      if !default_is_block?
        if val.is_a?(Enumerable)
          definition_error("'default' expects a single value but got '#{val}'")
        end
        attr_type.validate_value(self, val) do |msg|
          definition_error("'default' invalid - #{msg}")
        end
      end
    end
  end

  class AttributeArrayDef < AttributeBaseDef
    API = APIBuilder.define().include(AttributeBaseDef::API)

    def initialize
      super(:array)
    end

    def set_default(val = nil, &block)
      super
      if !default_is_block?
        if !val.is_a?(Array)
          definition_error("'default' expects an array but got '#{val.inspect_unquoted}'")
        end
        val.each do |elem|
          attr_type.validate_value(self, elem) do |msg|
            definition_error("'default' invalid - #{msg}")
          end
        end
      end
    end

    def post_create
      if type_id == :bool # Don't sort or strip dupes from arrays of bools
        set_flags :no_sort, :allow_dupes
      end
      super
    end
  end

  class AttributeHashDef < AttributeBaseDef
    API = APIBuilder.define(:key_type, :validate_key).include(AttributeBaseDef::API)

    def initialize
      super(:hash)
      @on_validate_key = nil
      @key_type = nil

      # Attributes that are stored as values in a hash have their corresponding key stored in their options. This is
      # used when cloning attributes. Store as __key to indicate it is internal and to stop it clashing with any user
      # defined option.
      #
      set_value_option(:__key)
    end

    def set_key_type(type_id)
      @key_type = Context.lookup_attr_type(type_id, fail_if_not_found: false)
      if @key_type.nil?
        definition_error("'#{type_id.inspect_unquoted}' must be one of #{Context.all_attr_types.map{|af| af.name}}")
      end
    end

    def key_type = @key_type
    def set_validate_key(&block) = @on_validate_key = block
    def on_validate_key = @on_validate_key

    def post_create
      super
      __check(:@key_type)
    end
  end
end
