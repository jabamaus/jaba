module JABA
  class AttributeType < Definition
    def initialize(default: nil)
      super()
      @default = default
    end

    def describe = "'#{name.inspect_unquoted}' attribute type"
    def default = @default

    def init_attr_def(attr_def); end            # override as necessary
    def post_create_attr_def(attr_def); end     # override as necessary
    def value_from_cmdline(str, attr_def) = str # override as necessary
    def validate_value(attr_def, value); end    # override as necessary
    def map_value(value, attr) = value          # override as necessary

    def post_create
      super
      @default.freeze
    end

    def type_error(value, expected)
      value_class = value.class
      if value_class == TrueClass || value_class == FalseClass
        value_class = "boolean"
      end
      if value.nil?
        yield "'nil' is invalid - expected #{expected}"
      else
        yield "'#{value.inspect_unquoted}' is a #{value_class.to_s.downcase} - expected #{expected}"
      end
    end
  end

  class AttributeTypeNull < AttributeType; end

  class AttributeTypeInt < AttributeType
    def initialize
      super(default: 0)
    end

    def validate_value(attr_def, value, &block)
      if !value.integer?
        type_error(value, "an integer", &block)
      end
    end

    def value_from_cmdline(str, attr_def)
      begin
        Integer(str)
      rescue
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - integer expected", want_err_line: false, want_backtrace: false)
      end
    end
  end

  class AttributeTypeString < AttributeType
    def initialize(default: "")
      super(default: default)
    end

    def validate_value(attr_def, value, &block)
      if !value.string? && !value.symbol?
        type_error(value, "a string or symbol", &block)
      end
    end

    # Can be specified as a symbol but stored internally as a string
    def map_value(value, attr)
      if value.is_a?(Symbol)
        value.to_s
      else
        value
      end
    end
  end

  class AttributeTypeBool < AttributeType
    def initialize
      super(default: false)
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
    APIBuilder.add_method(AttributeDefinitionAPI, :items)
    AttributeDefinition.class_eval do
      def items = @items

      def set_items(items)
        definition_warn("'items' contains duplicates") if items.uniq!
        @items.concat(items)
      end
    end

    def init_attr_def(attr_def)
      attr_def.instance_variable_set(:@items, [])
    end

    def post_create_attr_def(attr_def)
      super
      if attr_def.items.empty?
        attr_def.definition_error("'items' must be set")
      end
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

  class AttributeTypeUuid < AttributeTypeString
    def map_value(value, attr)
      Kernel.generate_uuid(namespace: "AttributeTypeUuid", name: value, braces: true)
    end
  end

  class AttributeTypeBasename < AttributeTypeString
    def validate_value(attr_def, value)
      super
      if value.contains_slashes?
        yield "'#{value}' must not contain slashes"
      end
    end
  end

  class AttributePathBase < AttributeTypeString
    # Register basedir_spec property into AttributeDefinition
    APIBuilder.add_method(AttributeDefinitionAPI, :basedir_spec)
    APIBuilder.add_method(AttributeDefinitionAPI, :basedir)
    AttributeDefinition.class_eval do
      def basedir_spec = @basedir_spec

      def set_basedir_spec(s)
        # check its valid
        @jdl_builder.lookup_definition(BasedirSpecDefinition, s, attr_def: self)
        @basedir_spec = s
      end

      def on_basedir = @on_basedir

      def set_basedir(&block)
        definition_error("basedir must be specified as a block") if !block
        @on_basedir = block
      end
    end

    def init_attr_def(attr_def)
      attr_def.instance_variable_set(:@basedir_spec, nil)
    end

    def post_create_attr_def(attr_def)
      super
      if attr_def.basedir_spec.nil?
        attr_def.set_basedir_spec(:jaba_file)
      end
    end

    def validate_value(attr_def, path)
      super
      path.validate_path do |msg|
        JABA.warn("#{attr_def.describe} not specified cleanly: #{msg}", line: $last_call_location)
      end
    end

    # TOOO: need to think carefully about how path specification works with shared defs
    # and how to force paths to be specified relative to jaba file.
    def map_value(value, attr)
      if value.absolute_path?
        value
      else
        ad = attr.attr_def
        base = if ad.on_basedir
            JABA.context.execute_attr_def_block(attr, ad.on_basedir)
          else
            case ad.basedir_spec
            when :jaba_file
              attr.src_loc.src_loc_info[0].parent_path
            when :definition_root
              attr.node[:root]
            else
              ad.definition_error("Unhandled basedir_spec #{ad.basedir_spec}")
            end
          end
        "#{base}/#{value}".cleanpath
      end
    end
  end

  class AttributeTypeFile < AttributePathBase; end

  class AttributeTypeDir < AttributePathBase
    def initialize
      super(default: ".")
    end
  end

  class AttributeTypeSrc < AttributePathBase; end

  class AttributeTypeCompound < AttributeType
    def init_attr_def(attr_def)
      attr_def.set_flags(:no_sort) if attr_def.array?
    end
  end
end
