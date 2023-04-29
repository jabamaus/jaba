module JABA
  class AttributeType < Definition
    def initialize(src_loc, name, default: nil)
      super(src_loc, name)
      @default = default
    end

    def describe = "'#{name.inspect_unquoted}' attribute type"
    def default = @default

    def init_attr_def(attr_def); end            # override as necessary
    def value_from_cmdline(str, attr_def) = str # override as necessary
    def map_value(value) = value                # override as necessary
    def validate_value(attr_def, value); end    # override as necessary

    def post_create
      super
      @default.freeze
    end

    def type_error(value, expected)
      value_class = value.class
      if value_class == TrueClass || value_class == FalseClass
        value_class = "boolean"
      end
      yield "'#{value.inspect_unquoted}' is a #{value_class.to_s.downcase} - expected #{expected}"
    end
  end

  class AttributeTypeNull < AttributeType; end

  class AttributeTypeString < AttributeType
    def initialize(src_loc, name)
      super(src_loc, name, default: '')
    end

    # Can be specified as a symbol but stored internally as a string
    def map_value(value)
      if value.is_a?(Symbol)
        value.to_s
      else
        value
      end
    end

    def validate_value(attr_def, value, &block)
      if !value.string?
        type_error(value, 'a string', &block)
      end
    end
  end

  class AttributeTypeSymbol < AttributeType
    def value_from_cmdline(str, attr_def)
      str.to_sym
    end

    def validate_value(attr_def, value, &block)
      if !value.symbol?
        type_error(value, 'a symbol', &block)
      end
    end
  end

  class AttributeTypeBool < AttributeType
    def initialize(src_loc, name)
      super(src_loc, name, default: false)
    end

    def value_from_cmdline(str, attr_def)
      case str
      when "true", "1"
        true
      when "false", "0"
        false
      else
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - [true|false|0|1] expected", want_err_line: false, want_backtrace: false)
      end
    end

    def validate_value(attr_def, value, &block)
      if !value.boolean?
        type_error(value, "[true|false]", &block)
      end
    end
  end

  class AttributeTypeChoice < AttributeType
    def value_from_cmdline(str, attr_def)
      items = attr_def.items
      # Use find_index to allow for nil being a valid choice
      index = items.find_index { |i| i.to_s == str }
      if index.nil?
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - [#{items.map { |i| i.to_s }.join("|")}] expected", want_err_line: false, want_backtrace: false)
      end
      items[index]
    end

    def validate_value(attr_def, value)
      items = attr_def.items
      if !items.include?(value)
        yield "must be one of #{items} but got '#{value.inspect_unquoted}'"
      end
    end
  end

  class AttributeTypeUuid < AttributeType
    def map_value(value)
      Kernel.generate_uuid(namespace: "AttributeTypeUuid", name: value, braces: true)
    end
  end

  class AttributePathBase < AttributeType
    def validate_value(attr_def, path)
      path.validate_path do |msg|
        JABA.warn("#{attr_def.describe} not specified cleanly: #{msg}", line: $last_call_location)
      end
    end
  end

  class AttributeTypeFile < AttributePathBase; end

  class AttributeTypeDir < AttributePathBase
    def initialize(src_loc, name)
      super(src_loc, name, default: ".")
    end
  end
  
  class AttributeTypeBasename < AttributePathBase
    def validate_value(attr_def, value)
      if value.contains_slashes?
        yield "'#{value}' must not contain slashes"
      end
    end
  end

  class AttributeTypeSrc < AttributePathBase; end

  class AttributeTypeCompound < AttributeType
    def init_attr_def(attr_def)
      attr_def.set_flags(:no_sort) if attr_def.array?
    end
  end
end
