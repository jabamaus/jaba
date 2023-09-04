module JABA
  class JDLBuilder < APIExposer
    def initialize(api_blocks = Context.standard_jdl_blocks)
      @building_jdl = false
      @all_definitions = []
      @path_to_node_def = KeyToSHash.new
      @path_to_attr_def = KeyToSHash.new
      @attrs_to_open = KeyToSHash.new
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
      @top_level_node_def = make_definition(NodeDef, "root", nil) do |d|
        d.set_title("TODO")
        d.set_api_class(@top_level_api_class)
      end
      @path_to_node_def[nil] = @top_level_node_def
      @target_defaults_attr_def = nil

      @building_jdl = true
      api_blocks.each do |b|
        api_execute(&b)
      end

      @attrs_to_open.each do |path, blocks|
        attr_def = lookup_attr_def(path)
        blocks.each do |block|
          attr_def.api_execute(&block)
        end
      end
      @building_jdl = false

      @all_definitions.each(&:post_create)

      @path_to_node_def.each do |path, node_def|
        node_def.attr_defs.sort_by! { |ad| ad.name }
        node_def.method_defs.sort_by! { |ad| ad.name }
      end
    end

    def building_jdl? = @building_jdl
    def common_attr_node_def = @common_attr_node_def
    def global_methods_node_def = @global_methods_node_def
    def top_level_node_def = @top_level_node_def

    expose :node

    def node(path, &block)
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

      sklass = node_def.parent_node_def&.api_class
      if sklass
        node_def.parent_node_def.method_defs.each do |m|
          api_class.undef_method(m.name)
        end
      end
    end

    def lookup_node_def(path)
      nd = @path_to_node_def[path]
      error("No '#{path}' node registered") if nd.nil?
      nd
    end

    def lookup_attr_def(path)
      ad = @path_to_attr_def[path]
      error("No '#{path}' attribute registered") if ad.nil?
      ad
    end

    expose :attr

    def attr(path, variant: :single, type: :null, &block)
      path = validate_path(path)
      parent_path, name = split_jdl_path(path)
      node_def = lookup_node_def(parent_path)

      attr_def = make_attribute(name, variant, type, block, node_def)
      @path_to_attr_def[path] = attr_def

      if name == "defaults"
        if !@target_defaults_attr_def.nil?
          error("@target_defaults_attr_def already set")
        end
        @target_defaults_attr_def = attr_def
      end

      if attr_def.has_flag?(:node_option)
        # If adding options to target node add same option to target defaults attr
        if node_def.name == "target"
          if @target_defaults_attr_def.nil?
            error("@target_defaults_attr_def is nil")
          end
          @target_defaults_attr_def.add_option_def(attr_def)
        end
        node_def.option_attr_defs << attr_def
      else
        node_def.attr_defs << attr_def
      end

      parent_class = node_def.api_class
      error("api class for '#{path}' node was nil") if parent_class.nil?

      if parent_class.method_defined?(name)
        error("Duplicate '#{path}' attribute registered")
      end
      # __call_loc is passed in in some unit tests.
      parent_class.define_method(name) do |*args, __call_loc: ::Kernel.calling_location, **kwargs, &attr_block|
        $last_call_location = __call_loc
        @node.jdl_process_attr(name, *args, __call_loc: $last_call_location, **kwargs, &attr_block)
      end
      case type
      when :bool
        parent_class.define_method("#{name}?") do |*args, **kwargs, &attr_block|
          $last_call_location = ::Kernel.calling_location
          if !args.empty? || !kwargs.empty? || attr_block
            JABA.error("'#{name}?' is a read only accessor and does not accept arguments", line: $last_call_location)
          end
          @node.jdl_process_attr(name, *args, __call_loc: $last_call_location, **kwargs, &attr_block)
        end
      when :compound
        # Compound attr interface inherits parent nodes interface so it has read only access to its attrs
        cmp_api = Class.new(parent_class)
        cmp_api.set_inspect_name(name)
        cmp_api.undef_method(name) # Ensure that compound cannot call itself recursively

        cmp_def = AttributeGroupDef.new
        cmp_def.instance_variable_set(:@jdl_builder, self)
        cmp_def.instance_variable_set(:@name, name)
        cmp_def.set_api_class(cmp_api)
        cmp_def.set_parent_node_def(node_def)
        attr_def.set_compound_def(cmp_def)
        @path_to_node_def[path] = cmp_def
      end
    end

    expose :open_attr

    def open_attr(path, &block)
      @attrs_to_open.push_value(path, block)
    end

    expose :global_method

    def global_method(name, &block)
      name = validate_name(name, regex: /^[a-zA-Z0-9_]+(\?)?$/)
      process_method(@global_methods_node_def, name, name, block)
    end

    expose :method

    def method(path, &block)
      path = validate_path(path)
      parent_path, name = split_jdl_path(path)

      node_def = if parent_path == "*"
          @common_methods_node_def
        else
          lookup_node_def(parent_path)
        end
      process_method(node_def, path, name, block)
    end

    def define_top_level_method(id, &block)
      if @top_level_api_class.method_defined?(id)
        JABA.error("'#{id}' method already defined")
      end
      @top_level_api_class.define_method(id, &block)
    end

    def process_method(node_def, path, name, block)
      klass = node_def.api_class
      if klass.method_defined?(name)
        error("Duplicate '#{path}' method registered")
      end

      meth_def = make_definition(MethodDef, name, block)
      node_def.method_defs << meth_def

      klass.define_method(name) do |*args, **kwargs, &block|
        $last_call_location = ::Kernel.calling_location
        @node.jdl_process_method(meth_def, block, *args, **kwargs)
      end
    end

    def make_definition(klass, name, block, add: true)
      d = klass.new
      d.instance_variable_set(:@jdl_builder, self)
      d.instance_variable_set(:@name, name)
      d.instance_variable_set(:@src_loc, last_call_location)
      d.instance_variable_set(:@last_call_location, last_call_location)
      yield d if block_given?
      d.api_execute(&block) if block
      @all_definitions << d if add
      d
    end

    def make_attribute(name, variant, type, block, node_def, add: true)
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

      attr_def = make_definition(def_class, name, block, add: add) do |ad|
        ad.set_node_def(node_def)
        ad.set_attr_type(type)
      end
      attr_def
    end

    def error(msg) = JABA.error(msg, line: last_call_location)

    def validate_name(name, regex: /^[a-zA-Z0-9_]+$/)
      if !name.is_a?(String) && !name.is_a?(Symbol)
        error("'#{name.inspect_unquoted}' must be a String or a Symbol but was a #{name.class}")
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

  class JDLDefinition < APIExposer
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
    def attribute? = false # overridden
    def method? = false # overridden

    expose :title, :set_title

    def set_title(t) = @title = t
    def title = @title

    expose :note, :set_note

    def set_note(n) = @notes << n
    def notes = @notes

    expose :example, :set_example

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
      line = @jdl_builder.building_jdl? ? last_call_location : src_loc
      JABA.error("#{describe} invalid - #{msg}", line: line)
    end

    def definition_warn(msg)
      line = @jdl_builder.building_jdl? ? last_call_location : src_loc
      JABA.warn(msg, line: line)
    end
  end

  class FlagOptionDef < JDLDefinition
    def initialize
      super()
      @transient = false
    end

    expose :transient, :set_transient
    def set_transient(t) = @transient = t
    def transient? = @transient
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
    def initialize
      super()
      @child_node_defs = []
    end

    def node_defs = @child_node_defs
    def reference_manual_page = "#{name}.html"
  end

  class MethodDef < JDLDefinition
    def initialize
      super()
      @on_called = nil
    end

    def method? = true

    # on_called is optional
    expose :on_called, :set_on_called

    def set_on_called(&block) = @on_called = block
    def on_called = @on_called
  end

  class AttributeBaseDef < JDLDefinition
    def initialize(variant)
      super()
      @variant = variant
      @attr_type = nil
      @flags = []
      @flag_option_defs = []
      @option_defs = []
      @flag_option_def_lookup = KeyToSHash.new
      @option_def_lookup = KeyToSHash.new
      @default = nil
      @default_is_block = false
      @default_set = false
      @on_validate = nil
      @on_set = nil
      @compound_def = nil # used by compound attribute
      @node_def = nil
    end

    def attribute? = true
    def set_node_def(nd) = @node_def = nd
    def node_def = @node_def
    def set_compound_def(d) = @compound_def = d
    def compound_def = @compound_def

    def set_attr_type(type_id)
      if type_id == :null && !JABA.running_tests?
        definition_error("'type' must be specified")
      end
      @attr_type = Context.lookup_attr_type(type_id, fail_if_not_found: false)
      if @attr_type.nil?
        definition_error("'#{type_id.inspect_unquoted}' must be one of #{Context.all_attr_type_names}")
      end
      @attr_type.init_attr_def(self)
    end

    def post_create
      __check(:@attr_type)
      @attr_type.post_create_attr_def(self)
      @flag_option_defs.each(&:post_create)
      @option_defs.each(&:post_create)
      super
      @default.freeze
      @flags.freeze
      @flag_option_defs.freeze
      @option_defs.freeze
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

    expose :flags, :set_flags

    def set_flags(*flags)
      flags.flatten.each do |f|
        fd = Context.lookup_attr_flag(f, fail_if_not_found: false)
        if fd.nil?
          definition_error("'#{f.inspect_unquoted}' must be one of #{Context.all_attr_flag_names}")
        end
        fd.compatible?(self) do |msg|
          definition_error("#{fd.describe} #{msg}")
        end
        fd.init_attr_def(self)
        @flags << f
      end
    end

    # TODO: check flag is valid
    def has_flag?(flag) = @flags.include?(flag)

    expose :flag_option, :add_flag_option
    def add_flag_option(name, &block)
      # TODO: check duplicate
      fodef = @jdl_builder.make_definition(FlagOptionDef, name, block, add: false)
      @flag_option_defs << fodef
      @flag_option_def_lookup[fodef.name] = fodef
    end

    def lookup_flag_option_def(name, attr, fail_if_not_found: true)
      od = @flag_option_def_lookup[name]
      if od.nil? && fail_if_not_found
        attr.attr_error("#{describe} does not support '#{name.inspect_unquoted}' flag option. Valid flags are #{@flag_option_defs.map(&:name)}")
      end
      od
    end

    def flag_option_defs = @flag_option_defs

    expose :option, :add_option

    def add_option(name, variant: :single, type: :null, &block)
      if type == :compound
        definition_error("'#{name.inspect_unquoted}' option cannot be of type :compound")
      end
      attr_def = @jdl_builder.make_attribute(name, variant, type, block, @node_def, add: false)
      add_option_def(attr_def)
    end

    def add_option_def(attr_def)
      @option_defs << attr_def
      @option_def_lookup[attr_def.name] = attr_def
    end

    def option_defs = @option_defs

    def lookup_option_def(name, attr, fail_if_not_found: true)
      od = @option_def_lookup[name]
      if od.nil? && fail_if_not_found
        attr.attr_error("#{describe} does not support '#{name.inspect_unquoted}' option")
      end
      od
    end

    expose :validate, :set_validate

    def set_validate(&block) = @on_validate = block
    def on_validate = @on_validate

    expose :on_set, :set_on_set

    def set_on_set(&block) = @on_set = block
    def on_set = @on_set

    def default = @default
    def default_is_block? = @default_is_block
    def default_set? = @default_set

    expose :default, :set_default

    def set_default(val = nil, &block)
      if type_id == :compound
        definition_error("compound attributes do not support a default value")
      end
      @default_set = true
      if block_given?
        @default = block
        @default_is_block = true
      else
        @default = val
      end
    end

    def validate_value(new_val); end # Override
  end

  class AttributeSingleDef < AttributeBaseDef
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
    def initialize
      super(:hash)
      @on_validate_key = nil
      @key_type = nil
    end

    expose :key_type, :set_key_type

    def set_key_type(type_id)
      @key_type = Context.lookup_attr_type(type_id, fail_if_not_found: false)
      if @key_type.nil?
        definition_error("'#{type_id.inspect_unquoted}' must be one of #{Context.all_attr_type_names}")
      end
    end

    def key_type = @key_type

    expose :validate_key, :set_validate_key

    def set_validate_key(&block) = @on_validate_key = block
    def on_validate_key = @on_validate_key

    def post_create
      super
      if @key_type.nil?
        set_key_type(:string)
      end
    end
  end
end
