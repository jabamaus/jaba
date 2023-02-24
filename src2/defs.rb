module JABA
  class Definition
    def initialize(src_loc, name)
      @src_loc = src_loc
      @name = name
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

    # Call from post_create when there is a problem with the definition
    def definition_error(msg, err_loc: src_loc)
      JABA.error("Error at #{err_loc.path.basename}:#{err_loc.lineno}: #{describe} invalid: #{msg}")
    end

    def definition_warn(msg, warn_loc: src_loc)
      JABA.warn("Warning at #{warn_loc.path.basename}:#{warn_loc.lineno}: #{msg}")
    end
  end

  class FlagDefinition < Definition
    def initialize(src_loc, name)
      super
      @on_compatible = nil
    end

    def describe = "'#{@id.inspect_unquoted}' attribute definition flag"
    def set_compatible?(&block) = @on_compatible = block
  end

  class MethodDefinition < Definition
    def initialize(src_loc, name)
      super
      @on_called = nil
    end

    def set_on_called(&block) = @on_called = block

    def post_create
      super
      __check(:@on_called)
    end
  end

  class AttributeDefinition < Definition
    def initialize(src_loc, name, variant, attr_type)
      super(src_loc, name)
      @variant = variant
      @attr_type = attr_type
      @flags = []
      @flag_options = []
      @value_options = []
      @items = []
      @default = nil
      @default_is_block = false
    end

    def describe = "'#{@name.inspect_unquoted}' #{@variant == :single ? "" : "#{@variant} "}attribute"
    def variant = @variant
    def attr_type = @attr_type
    def type_id = @attr_type.name

    def set_flags(*flags) = @flags.concat(flags)
    def has_flag?(flag) = @flags.include?(flag)
    def get_flag_options = @flag_options
    def set_flag_options(*fo) = @flag_options.concat(fo)
    def has_flag_option?(fo) = @flag_options.include?(fo)
    def get_items = @items
    def set_items(items) = @items.concat(items)

    ValueOption = Data.define(:name, :required, :items)

    def set_value_option(name, required: false, items: [])
      if !name.symbol?
        JABA.error("In #{describe} value_option id must be specified as a symbol, eg :option")
      end
      @value_options << ValueOption.new(name, required, items)
    end

    def get_value_option(name)
      if @value_options.empty?
        JABA.error("Invalid value option '#{name.inspect_unquoted}' - no options defined in #{describe}")
      end
      vo = @value_options.find { |v| v.name == name }
      if !vo
        JABA.error("Invalid value option '#{name.inspect_unquoted}'. Valid #{describe} options: #{@value_options.map { |v| v.name }}")
      end
      vo
    end

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

    def post_create
      super
      if @default.nil? && !attr_type.default.nil? && !has_flag?(:required)
        @default = attr_type.default
      end
      @default.freeze if !@default.nil?
      @flags.freeze
      @flag_options.freeze

      if attr_type.name == :choice
        if @items.empty?
          definition_error("'items' must be set")
        elsif items.uniq!
          definition_warn("'items' contains duplicates")
        end
      end
    end

    def validate_value(new_val); end # Override
  end

  class AttributeSingleDefinition < AttributeDefinition
    def initialize(src_loc, name, attr_type)
      super(src_loc, name, :single, attr_type)
    end

    def validate_value(val)
      if val.is_a?(Enumerable)
        JABA.error("#{describe} must be a single value not a '#{val.class}'")
      end
    end

    def set_default(val = nil, &block)
      super
      if !default_is_block? && @default.is_a?(Enumerable)
        definition_error("'default' expects a single value but got '#{@default}'", err_loc: APIBuilder.last_call_location)
      end
      begin
        attr_type.validate_value(self, val)
      rescue => e
        definition_error("'default' invalid: #{e.message}", err_loc: APIBuilder.last_call_location)
      end
    end
  end

  class AttributeArrayDefinition < AttributeDefinition
    def initialize(src_loc, name, attr_type)
      super(src_loc, name, :array, attr_type)
    end
  end

  class AttributeHashDefinition < AttributeDefinition
    def initialize(src_loc, name, attr_type)
      super(src_loc, name, :hash, attr_type)
    end
  end
end
