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
      definition_error_post_create("var must be specified as a symbol") if !var.symbol?
      if instance_variable_get(var).nil?
        definition_error_post_create("#{describe} requires '#{var.to_s.delete_prefix("@")}' to be specified")
      end
    end

    def definition_error(msg, err_loc: APIBuilder.last_call_location)
      JABA.error("Error at #{err_loc.src_loc_describe}: #{describe} invalid: #{msg}")
    end

    def definition_error_post_create(msg)
      definition_error(msg, err_loc: src_loc)
    end

    def definition_warn(msg, warn_loc: APIBuilder.last_call_location)
      puts("Warning at #{warn_loc.src_loc_describe}: #{msg}")
    end

    def definition_warn_post_create(msg)
      definition_warn(msg, warn_loc: src_loc)
    end
  end

  class FlagDefinition < Definition
    @@all = []
    def self.all = @@all

    def initialize(src_loc, name)
      super
      @@all << self
      @on_compatible = nil
    end

    def describe = "'#{name.inspect_unquoted}' attribute definition flag"

    def set_compatible?(&block) = @on_compatible = block
    def check_compatibility(attr_def)
      instance_exec(attr_def, &@on_compatible) if @on_compatible
    end

    def self.lookup(name) = all.find{|fd| fd.name == name}
  end

  class MethodDefinition < Definition
    def initialize(src_loc, name)
      super
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
      @default_set = false
      @on_validate = nil
    end

    def describe = "'#{@name.inspect_unquoted}' #{@variant == :single ? "" : "#{@variant} "}attribute"
    def variant = @variant
    def array? = @variant == :array
    def attr_type = @attr_type
    def type_id = @attr_type.name

    def set_flags(*flags)
      flags.flatten.each do |f|
        fd = FlagDefinition.lookup(f)
        if fd.nil?
          definition_error("'#{f.inspect_unquoted}' flag does not exist")
        end
        fd.check_compatibility(self)
        @flags << f
      end
    end
    def has_flag?(flag) = @flags.include?(flag)
    def get_flag_options = @flag_options
    def set_flag_options(*fo) = @flag_options.concat(fo)
    def has_flag_option?(fo) = @flag_options.include?(fo)
    def get_items = @items

    def set_items(items)
      definition_warn("'items' contains duplicates") if items.uniq!
      @items.concat(items)
    end

    def set_validate(&block) = @on_validate = block
    def on_validate = @on_validate

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

    def post_create
      super
      @default.freeze
      @flags.freeze
      @flag_options.freeze

      if type_id == :choice && @items.empty?
        definition_error_post_create("'items' must be set")
      end
    end

    def validate_value(new_val); end # Override
  end

  class AttributeSingleDefinition < AttributeDefinition
    def initialize(src_loc, name, attr_type)
      super(src_loc, name, :single, attr_type)
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
        yield "#{describe} must be a single value not a '#{val.class}'"
      end
    end

    def set_default(val = nil, &block)
      super
      if !default_is_block?
        if val.is_a?(Enumerable)
          definition_error("'default' expects a single value but got '#{val}'")
        end
        attr_type.validate_value(self, val) do |msg|
          definition_error("'default' invalid: #{msg}")
        end
      end
    end
  end

  class AttributeArrayDefinition < AttributeDefinition
    def initialize(src_loc, name, attr_type)
      super(src_loc, name, :array, attr_type)
    end

    def set_default(val = nil, &block)
      super
      if !default_is_block?
        if !val.is_a?(Array)
          definition_error("'default' expects an array but got '#{val}'")
        end
        val.each do |elem|
          attr_type.validate_value(self, elem) do |msg|
            definition_error("'default' invalid: #{msg}")
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
    def initialize(src_loc, name, attr_type)
      super(src_loc, name, :hash, attr_type)
      @on_validate_key = nil
    end

    def set_validate_key(&block) = @on_validate_key = block
    def on_validate_key = @on_validate_key
  end
end
