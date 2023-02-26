module JABA
  class AttributeType < Definition
    def initialize(name, default: nil)
      super(calling_location, name)
      @default = default
    end

    def self.singleton = @instance ||= self.new.tap { |i| i.post_create }

    def describe = "'#{name.inspect_unquoted}' attribute type"
    def default = @default

    def from_cmdline(str, attr_def) = str    # override as necessary
    def map_value(value) = value             # override as necessary
    def validate_value(attr_def, value); end # override as necessary

    def post_create
      super
      @default.freeze
    end

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
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - [true|false|0|1] expected", want_err_line: false, want_backtrace: false)
      end
    end

    # TODO: move to attribute def
    #def post_init_attr_def(attr_def)
    #  if attr_def.array?
    #    attr_def.flags [:no_sort, :allow_dupes]
    #  end
    #end

    def validate_value(attr_def, value)
      if !value.boolean?
        raise_type_error(value, "[true|false]")
      end
    end
  end

  class AttributeTypeChoice < AttributeType
    def initialize
      super(:choice)
      set_title "Choice attribute type"
      set_note "Can take exactly one of a set of unique values"
    end

    def from_cmdline(str, attr_def)
      items = attr_def.get_items
      # Use find_index to allow for nil being a valid choice
      index = items.find_index { |i| i.to_s == str }
      if index.nil?
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - [#{items.map { |i| i.to_s }.join("|")}] expected", want_err_line: false, want_backtrace: false)
      end
      items[index]
    end

    def validate_value(attr_def, value)
      items = attr_def.get_items
      if !items.include?(value)
        JABA.error("Must be one of #{items} but got '#{value.inspect_unquoted}'")
      end
    end
  end
end
