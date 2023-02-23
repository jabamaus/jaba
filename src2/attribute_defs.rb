module JABA
  class Documentable
    def initialize
      @title = nil
      @notes = []
      @examples = []
    end

    def set_title(t) = @title = t
    def set_note(n) = @notes << n
    def set_example(e) = @examples << e

    def __validate
      __check(:@title) if !JABA.running_tests?
      @title.freeze
      @notes.freeze
      @examples.freeze
    end

    def __check(var)
      JABA.error("var must be specified as a symbol") if !var.symbol?
      if instance_variable_get(var).nil?
        JABA.error("'#{describe}' requires '#{var.to_s.delete_prefix("@")}' to be specified")
      end
    end
  end

  class Definition < Documentable
    def initialize(name)
      super()
      @name = name
    end

    def name = @name
    def describe = "'#{name.inspect_unquoted}'"

    def __validate
      super
      @name.freeze
    end
  end

  class FlagDefinition < Definition
    def initialize(name)
      super(name)
      @on_compatible = nil
      @on_init_attr_def = nil
    end

    def describe = "#{@id.inspect} attribute definition flag"
    def set_compatible?(&block) = @on_compatible = block
    def init_attr_def(&block) = @on_init_attr_def = block

    def __validate
      super
    end
  end

  class MethodDefinition < Definition
    def initialize(name)
      super
      @on_called = nil
    end

    def set_on_called(&block) = @on_called = block

    def __validate
      super
      __check(:@on_called)
    end
  end

  class AttributeDefinition < Definition
    def initialize(name, variant, attr_type)
      super(name)
      @variant = variant
      @attr_type = attr_type
      @flags = []
      @flag_options = []
      @default = nil
      @default_is_block = false
    end

    def type_id = @attr_type.id
    def set_flags(*flags) = @flags.concat(flags)
    def has_flag?(flag) = @flags.include?(flag)
    def get_flag_options = @flag_options
    def set_flag_options(*fo) = @flag_options.concat(fo)
    def has_flag_option?(fo) = @flag_options.include?(fo)

    def get_default = @default
    def default_is_block? = @default_is_block
    def set_default(val = nil, &block)
      if block_given?
        @default = block
        @default_is_block = true
      else
        @default = val
      end
    end

    def variant = @variant
    def attr_type = @attr_type

    def describe
      "'#{@name.inspect_unquoted}' #{@variant == :single ? "" : "#{@variant} "}attribute"
    end

    def __validate
      super
      if @default.nil? && !@attr_type.default.nil? && !has_flag?(:required)
        @default = @attr_type.default
      end
    end

    def validate_value(new_val)
    end

    def call_validators(what)
      begin
        yield
      rescue => e
        JABA.error("#{what} invalid: #{e.message}", backtrace: APIBuilder.last_call_location)
      end
    end
  end

  class AttributeSingleDefinition < AttributeDefinition
    def initialize(name, attr_type)
      super(name, :single, attr_type)
    end

    def validate_value(val)
      if val.is_a?(Enumerable)
        JABA.error("#{describe} must be a single value not a '#{val.class}'")
      end
    end

    def set_default(val = nil, &block)
      super
      if !default_is_block? && @default.is_a?(Enumerable)
        JABA.error("'default' expects a single value but got '#{@default}'.", backtrace: APIBuilder.last_call_location)
      end
      call_validators("#{describe} default") do
        attr_type.validate_value(self, val)
      end
    end

    def __validate
      super
    end
  end

  class AttributeArrayDefinition < AttributeDefinition
    def initialize(name, attr_type)
      super(name, :array, attr_type)
    end
  end

  class AttributeHashDefinition < AttributeDefinition
    def initialize(name, attr_type)
      super(name, :hash, attr_type)
    end
  end
end
