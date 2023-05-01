module JABA
  class Definition
    def initialize
      @jdl_builder = nil # set by JDLBuilder
      @src_loc = nil # Set by JDLBuilder
      @name = nil # Set by JDLBuilder
      @title = nil
      @notes = []
      @examples = []
    end

    def src_loc = @src_loc
    def name = @name
    def describe = "'#{name.inspect_unquoted}'"

    def set_title(t) = @title = t
    def set_note(n) = @notes << n
    def set_example(e) = @examples << e

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
      JABA.error("#{describe} invalid - #{msg}", line: APIBuilder.last_call_location)
    end

    def definition_warn(msg)
      JABA.warn(msg, line: APIBuilder.last_call_location)
    end
  end

  class FlagDefinition < Definition
    def initialize
      super()
      @on_compatible = nil
    end

    def describe = "'#{name.inspect_unquoted}' attribute definition flag"

    def set_compatible?(&block) = @on_compatible = block

    def check_compatibility(attr_def)
      instance_exec(attr_def, &@on_compatible) if @on_compatible
    end
  end

  class BasedirSpecDefinition < Definition
    def describe = "'#{name.inspect_unquoted}' basedir_spec"
  end

  class NodeDefinition < Definition
    def initialize
      super()
    end
  end

  class MethodDefinition < Definition
    def initialize
      super()
      @on_called = nil
    end

    def set_on_called(&block) = @on_called = block
    def on_called = @on_called

    def post_create
      super
      __check(:@on_called)
    end
  end

  class AttributeDefinition < Definition
    def initialize(variant)
      super()
      @variant = variant
      @flags = []
      @flag_options = []
      @value_options = []
      @items = []
      @default = nil
      @default_is_block = false
      @default_set = false
      @on_validate = nil
      @basedir_spec = nil
      @compound_api = nil # used by compound attribute
    end

    def set_attr_type(t) = @attr_type = t
      
    def post_create
      super
      @default.freeze
      @flags.freeze
      @flag_options.freeze

      if type_id == :choice && @items.empty?
        definition_error("'items' must be set")
      end
    end

    def describe = "'#{@name.inspect_unquoted}' #{@variant == :single ? "" : "#{@variant} "}attribute"
    def variant = @variant
    def array? = @variant == :array
    def compound? = type_id == :compound
    def attr_type = @attr_type
    def type_id = @attr_type.name

    def set_flags(*flags)
      flags.flatten.each do |f|
        fd = @jdl_builder.lookup_definition(FlagDefinition, f, attr_def: self)
        fd.check_compatibility(self)
        @flags << f
      end
    end

    def has_flag?(flag) = @flags.include?(flag)
    def flag_options = @flag_options
    def set_flag_options(*fo) = @flag_options.concat(fo)
    def has_flag_option?(fo) = @flag_options.include?(fo)

    # Items is used by choice attribute
    def items = @items

    def set_items(items)
      definition_warn("'items' contains duplicates") if items.uniq!
      @items.concat(items)
    end

    # basedir_spec is used by path attributes
    def basedir_spec = @basedir_spec

    def set_basedir_spec(s)
      @basedir_spec = @jdl_builder.lookup_definition(BasedirSpecDefinition, s, attr_def: self)
    end

    def set_validate(&block) = @on_validate = block
    def on_validate = @on_validate

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

    def set_compound_api(api) = @compound_api = api
    def compound_api = @compound_api

    def validate_value(new_val); end # Override
  end

  class AttributeSingleDefinition < AttributeDefinition
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

  class AttributeArrayDefinition < AttributeDefinition
    def initialize
      super(:array)
    end

    def set_default(val = nil, &block)
      super
      if !default_is_block?
        if !val.is_a?(Array)
          definition_error("'default' expects an array but got '#{val}'")
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

  class AttributeHashDefinition < AttributeDefinition
    def initialize
      super(:hash)
      @on_validate_key = nil
      @key_type = nil
    end

    def set_key_type(key_type)
      @key_type = @jdl_builder.lookup_definition(:attr_types, key_type)
    end
    def key_type = @key_type
    def set_validate_key(&block) = @on_validate_key = block
    def on_validate_key = @on_validate_key

    def post_create
      super
      if @key_type.nil?
        definition_error("key_type must be set")
      end
    end
  end
end
