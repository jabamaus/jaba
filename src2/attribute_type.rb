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
    def map_value_array(value, attr_array, **kwargs) = value    # override as necessary

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

  class AttributeTypeTo_s < AttributeType
    def initialize(default: "")
      super(default: default)
    end

    def validate_value(attr_def, value, &block)
      if !value.respond_to?(:to_s)
        type_error(value, "respond to :to_s", &block)
      end
    end

    def map_value(value, attr)
      value.to_s
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
    APIBuilder.add_method(AttributeDefinitionCommonAPI, :items)
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
      Kernel.generate_uuid(namespace: "JabaAttributeTypeUUID", name: value, braces: true)
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

  class AttributeTypeExt < AttributeTypeString
    def validate_value(attr_def, value)
      super
      if !value.start_with?(".")
        yield "'#{value}' extension must start with '.'"
      end
    end
  end

  class AttributePathBase < AttributeTypeString
    # Register basedir into AttributeDefinition
    ValidBaseDirs = [:definition_root, :jaba_file]

    APIBuilder.add_method(AttributeDefinitionCommonAPI, :basedir)
    AttributeDefinition.class_eval do
      def basedir = @basedir

      def set_basedir(spec = nil, &block)
        if (spec && block) || (!spec && !block)
          definition_error("basedir must be specified as a spec or a block")
        end
        if spec && !ValidBaseDirs.include?(spec)
          definition_error("'#{spec.inspect_unquoted}' must be one of #{ValidBaseDirs}")
        end
        @basedir = spec ? spec : block
      end
    end

    def init_attr_def(attr_def)
      attr_def.set_flag_options(:force)
      attr_def.instance_variable_set(:@basedir, nil)
    end

    def post_create_attr_def(attr_def)
      super
      if attr_def.basedir.nil?
        attr_def.set_basedir(:jaba_file)
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
    def map_value(path, attr)
      return path if path.empty?
      abs_path = make_path_absolute(path, attr)
      if !JABA.context.file_manager.exist?(abs_path) &&
         !attr.attr_def.has_flag?(:no_check_exist) &&
         !attr.has_flag_option?(:force)
        JABA.error("'#{abs_path.inspect_unquoted}' does not exist on disk - use :force to add anyway.", line: $last_call_location)
      end
      abs_path
    end

    def make_path_absolute(path, attr)
      return path if path.absolute_path?
      ad = attr.attr_def
      base = case ad.basedir
        when Proc
          JABA.context.execute_attr_def_block(attr, ad.basedir)
        when :jaba_file
          attr.node.src_dir
        when :definition_root
          attr.node[:root]
        else
          ad.definition_error("Unhandled basedir #{ad.basedir}")
        end
      "#{base}/#{path}".cleanpath
    end
  end

  class AttributeTypeFile < AttributePathBase; end

  class AttributeTypeDir < AttributePathBase
    def initialize
      super(default: ".")
    end
  end

  SrcFileInfo = Data.define(
    :absolute_path,
    :projdir_rel,
    :vpath,
    :file_type,
    :extname
  )
  SrcFileInfo.define_method :<=> do |other|
    absolute_path <=> other.absolute_path
  end

  class AttributeTypeSrc < AttributePathBase
    def init_attr_def(attr_def)
      super
      attr_def.set_value_option(:vpath)
    end

    def map_value(value, attr)
      abs_path = super
      SrcFileInfo.new(abs_path, nil, nil, nil, abs_path.extname)
    end

    def map_value_array(path, attr_array)
      abs_path = make_path_absolute(path, attr_array)
      fm = JABA.context.file_manager
      is_dir = fm.directory?(abs_path)
      is_wc = abs_path.wildcard?
      return abs_path if !is_wc && !is_dir
 
      src_ext = [".cpp", ".h"] # TODO
      
      files = if is_wc
        extname = abs_path.extname
        src_ext << extname if !extname.empty? # ensure explicitly specified extensions are included
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
      files = files.select{|f| src_ext.include?(f.extname)}
      files
    end
  end

  class AttributeTypeCompound < AttributeType
    def init_attr_def(attr_def)
      attr_def.set_flags(:no_sort) if attr_def.array?
    end
  end
end
