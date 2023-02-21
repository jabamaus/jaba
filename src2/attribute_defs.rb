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
      @flags = nil
      @default = nil
    end

    def set_flags(*flags) = @flags = flags

    def set_default(val = nil, &block)
      if block_given?
        @default = block
      else
        @default = val
        call_validators("#{describe} default") do
          case @variant
          when :single, :array
            @attr_type.validate_value(self, val)
          when :hash
            val.each do |key, v|
              @attr_key_type.validate_value(self, key)
              @attr_type.validate_value(self, v)
            end
          end
        end
      end
    end

    def variant = @variant
    def attr_type = @attr_type

    def describe
      "'#{@name.inspect_unquoted}' #{@variant == :single ? "" : "#{@variant} "}attribute"
    end

    def has_flag?(flag) = @flags&.include?(flag)
    def get_default = @default

    def __validate
      super
      if @default.nil? && !@attr_type.default.nil? && !has_flag?(:required)
        @default = @attr_type.default
      end
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
