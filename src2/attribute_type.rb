module JABA
  class AttributeType
    def initialize(name, default: nil)
      @name = name
      @default = default
      @default.freeze
    end

    def name = @name
    def describe = "'#{@name.inspect_unquoted}' attribute type"
    def default = @default

    def init_attr_def(attr_def); end            # override as necessary
    def post_create_attr_def(attr_def); end     # override as necessary
    def value_from_cmdline(str, attr_def) = str # override as necessary
    def validate_value(attr_def, value); end    # override as necessary
    def map_value(value, attr) = value          # override as necessary
    def map_value_array(value, attr_array, **kwargs) = value    # override as necessary

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

  class AttributeTypeNull < AttributeType
    def initialize = super(:null)
  end

  class AttributeTypeInt < AttributeType
    def initialize(name = :int) = super(name, default: 0)

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

  class JABAString < ::String
    def to_jaba_string = self

    alias_method :old_equals, :==

    def ==(other)
      old_equals(other.symbol? ? other.to_jaba_string : other)
    end
  end

  class ::Symbol
    def to_jaba_string = JABAString.new(name) # Symbol#name returns frozen string

    alias_method :old_case_equals, :===

    def ===(other)
      old_case_equals(other.is_a?(JABAString) ? other.to_sym : other)
    end
  end

  class ::String
    def to_jaba_string = JABAString.new(self)
  end

  class AttributeTypeString < AttributeType
    def initialize(name = :string, default: JABAString.new) = super(name, default: default)

    def validate_value(attr_def, value, &block)
      if !value.string? && !value.symbol?
        type_error(value, "a string or symbol", &block)
      end
    end

    # Can be specified as a symbol but stored internally as a string
    def map_value(value, attr) = value.to_jaba_string
  end

  class AttributeTypeTo_s < AttributeType
    def initialize(name = :to_s, default: JABAString.new) = super(name, default: default)

    def validate_value(attr_def, value, &block)
      if !value.respond_to?(:to_s)
        type_error(value, "respond to :to_s", &block)
      end
    end

    def map_value(value, attr) = value.to_s.to_jaba_string
  end

  class AttributeTypeBool < AttributeType
    def initialize(name = :bool) = super(name, default: false)

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
    AttributeBaseDef.class_eval do
      def items = @items

      expose :items, :set_items

      def set_items(items)
        definition_warn("'items' contains duplicates") if items.uniq!
        @items.concat(items)
      end
    end

    def initialize(name = :choice) = super(name)

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
    def initialize(name = :uuid) = super(name)

    def map_value(value, attr)
      Kernel.generate_uuid(namespace: "JabaAttributeTypeUUID", name: value, braces: true)
    end
  end

  class AttributeTypeBasename < AttributeTypeString
    def initialize(name = :basename) = super(name)

    def validate_value(attr_def, value)
      super
      if value.contains_slashes?
        yield "'#{value}' must not contain slashes"
      end
    end
  end

  class AttributeTypeExt < AttributeTypeString
    def initialize(name = :ext) = super(name)

    def validate_value(attr_def, value)
      super
      if !value.empty? && !value.start_with?(".")
        yield "'#{value}' extension must start with '.'"
      end
    end
  end

  class AttributePathBase < AttributeTypeString
    # Register base_attr into AttributeDef
    AttributeBaseDef.class_eval do
      expose :base_attr, :set_base_attr

      def base_attr = @base_attr
      def set_base_attr(attr_name) = @base_attr = attr_name
    end

    def init_attr_def(attr_def)
      attr_def.set_flag_options(:force)
      attr_def.instance_variable_set(:@base_attr, nil)
    end

    def validate_value(attr_def, path)
      super
      if path.wildcard? && !attr_def.array?
        yield "only array attributes can accept wildcards"
      end
      path.validate_path do |msg|
        JABA.warn("#{attr_def.describe} not specified cleanly: #{msg}", line: $last_call_location)
      end
    end

    # TOOO: need to think carefully about how path specification works with shared defs
    # and how to force paths to be specified relative to jaba file.
    def map_value(path, attr)
      return path if path.empty?
      abs_path = make_path_absolute(path, attr)
      if !JABA.context.file_manager.exist?(abs_path) &&
         !attr.attr_def.has_flag?(:no_check_exist) &&
         !attr.has_flag_option?(:force)
        attr.attr_error("'#{abs_path.inspect_unquoted}' does not exist on disk - use :force to add anyway.")
      end
      abs_path
    end

    def make_path_absolute(path, attr)
      return path if path.absolute_path?
      ba = attr.attr_def.base_attr
      base = case ba
        when nil
          attr.node.src_dir
        else
          battr = attr.node.search_attr(ba)
          if battr.type_id != :dir
            attr.attr_error("#{attr.describe} has #{battr.describe} as its base dir but #{battr.describe} is of type '#{battr.type_id}' but must be ':dir'")
          end
          battr.value
        end
      "#{base}/#{path}".cleanpath
    end
  end

  class AttributeTypeFile < AttributePathBase
    def initialize(name = :file) = super(name)
  end

  class AttributeTypeDir < AttributePathBase
    def initialize(name = :dir) = super(name, default: ".")
  end

  class AttributeTypeSrc < AttributePathBase
    def initialize(name = :src) = super(name)

    def map_value_array(path, attr_array)
      abs_path = make_path_absolute(path, attr_array)
      fm = JABA.context.file_manager
      is_dir = fm.directory?(abs_path)
      is_wc = abs_path.wildcard?
      return abs_path if !is_wc && !is_dir

      @src_ext ||= JABA.context.root_node[:src_ext]
      extname = nil

      files = if is_wc
          extname = abs_path.extname if !abs_path.extname.empty?
          fm.glob_files(abs_path)
        elsif is_dir
          if !fm.exist?(abs_path)
            attr_array.attr_error("'#{abs_path}' does not exist on disk")
          end
          fm.glob_files("#{abs_path}/**/*")
        end

      if files.empty?
        JABA.warn("'#{abs_path}' did not match any files ", line: attr_array.last_call_location)
        return files
      end
      files = files.select { |f| extname == f.extname || @src_ext.include?(f.extname) }
      files
    end
  end

  class AttributeTypeCompound < AttributeType
    def initialize = super(:compound)

    def init_attr_def(attr_def)
      attr_def.set_flags(:no_sort) if attr_def.array?
    end

    def validate_value(attr_def, value)
      yield "compound cannot be nil" if value.nil?
    end
  end

  class AttributeTypeBlock < AttributeType
    def initialize = super(:block)

    def init_attr_def(attr_def)
      attr_def.set_flags(:no_sort, :allow_dupes) if attr_def.array?
    end

    def validate_value(attr_def, value)
      yield "must be a block" if !value.proc?
    end
  
    def map_value(value, attr)
      block = value
      attr.node.eval_jdl(&block)
      block
    end
  end
end
