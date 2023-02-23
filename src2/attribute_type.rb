module JABA
  class AttributeType < Documentable
    def initialize(id, default: nil)
      super()
      @id = id
      @default = default
    end

    def self.singleton = @instance ||= self.new.tap { |i| i.__validate }

    def id = @id
    def describe = "#{id} attribute type"
    def default = @default

    def __validate
      super
      __check(:@id)
      @id.freeze
      @default.freeze
    end

    def from_cmdline(str, attr_def) = str
    def map_value(value) = value

    def init_attr_def(attr_def); end
    def post_init_attr_def(attr_def); end
    def validate_value(attr_def, value); end

    def raise_type_error(value, expected)
      value_class = value.class
      if value_class == TrueClass || value_class == FalseClass
        value_class = "boolean"
      end
      JABA.error("'#{value.inspect_unquoted}' is a #{value_class.to_s.downcase} - expected #{expected}")
    end
  end

  class AttributeTypeNull < AttributeType
    def initialize
      super(:null)
      set_title "Null attribute type"
    end
  end

  class AttributeTypeBool < AttributeType
    def initialize
      super(:bool, default: false)
      set_title "Boolean attribute type"
      set_note "Accepts [true|false]. Defaults to false unless value must be supplied by user."
    end

    def from_cmdline(str, attr_def)
      case str
      when "true", "1"
        true
      when "false", "0"
        false
      else
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - [true|false|0|1] expected", want_backtrace: false)
      end
    end

    def post_init_attr_def(attr_def)
      if attr_def.array?
        attr_def.flags [:no_sort, :allow_dupes]
      end
    end

    def validate_value(attr_def, value)
      if !value.boolean?
        raise_type_error(value, "[true|false]")
      end
    end
  end
end
