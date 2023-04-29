module JABA
  class AttributeType < Definition
    def initialize(name, default: nil)
      super(calling_location, name)
      @default = default
    end

    def self.singleton = @instance ||= new.tap { |i| i.post_create }

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

  class AttributeTypeNull < AttributeType
    def initialize
      super(:null)
      set_title "Null attribute type"
    end
  end

  class AttributeTypeString < AttributeType
    def initialize
      super(:string, default: '')
      set_title "String attribute type"
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
    def initialize
      super(:symbol)
      set_title "Symbol attribute type"
    end

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
    def initialize
      super(:bool, default: false)
      set_title "Boolean attribute type"
      set_note "Accepts [true|false]. Defaults to false unless value must be supplied by user."
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
    def initialize
      super(:choice)
      set_title "Choice attribute type"
      set_note "Can take exactly one of a set of unique values"
    end

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
    def initialize
      super(:uuid)
      set_title "UUID attribute type"
    end
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

  class AttributeTypeFile < AttributePathBase
    def initialize
      super(:file)
      set_title "File attribute type"
      set_note "Validates that value is a string path representing a file"
    end
  end

  class AttributeTypeDir < AttributePathBase
    def initialize
      super(:dir, default: ".")
      set_title "Directory attribute type"
      set_note "Validates that value is a string path representing a directory"
    end
  end

  class AttributeTypeSrc < AttributePathBase
    def initialize
      super(:src)
      set_title "Source file specification pattern"
      set_note "Can be file glob match an explicit path or a directory"
    end
  end

  class AttributeTypeBasename < AttributePathBase
    def initialize
      super(:basename)
      set_title "basename attribute type"
      set_note "Basename of a file. Slashes are rejected."
    end

    def validate_value(attr_def, value)
      if value.contains_slashes?
        yield "'#{value}' must not contain slashes"
      end
    end
  end

  class AttributeTypeCompound < AttributeType
    def initialize
      super(:compound)
      set_title "Compound attribute type"
    end

    def init_attr_def(attr_def)
      attr_def.set_flags(:no_sort) if attr_def.array?
    end
  end
end
