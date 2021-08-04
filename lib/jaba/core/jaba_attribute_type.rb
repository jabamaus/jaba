# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType
    
    attr_reader :services
    attr_reader :id
    attr_reader :title
    attr_reader :notes
    attr_reader :default

    ##
    #
    def initialize(id, title, default: nil)
      @id = id
      @title = title
      @default = default
      @notes = nil
    end

    ##
    #
    def describe
      "#{@id} attribute type"
    end

    ##
    #
    def post_create
      JABA.error("id must be specified") if id.nil?
      JABA.error("#{describe} must have a title") if title.nil?
      @id.freeze
      @title.freeze
      @default.freeze
      @notes.freeze
    end

    ##
    #
    def from_cmdline(str, attr_def)
      str
    end
    
    ##
    #
    def map_value(value)
      value
    end

    ##
    #
    def get_reference_manual_rows(attr_def)
      nil
    end

    ##
    # If an attribute type requires additional properties (eg choice attribute requires items), override this.
    #
    def init_attr_def(attr_def)
    end

    ##
    #
    def post_init_attr_def(attr_def)
    end

    ##
    #
    def validate_value(attr_def, value)
    end

  end

  ##
  #
  class JabaAttributeTypeString < JabaAttributeType
    
    ##
    #
    def initialize
      super(:string, 'String attribute type', default: '')
      @notes = 'Only explicit strings will be accepted. Symbols are not valid. Defaults to empty string unless value must be specified by user.'
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.string?
        JABA.error("'#{value}' must be a string but was a '#{value.class}'")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeSymbol < JabaAttributeType
    
    ##
    #
    def initialize
      super(:symbol, 'Symbol attribute type')
      @notes = 'Only explicit symbols will be accepted. Strings are not valid.'
    end

    ##
    #
    def from_cmdline(str, attr_def)
      str.to_sym
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.symbol?
        JABA.error("'#{value}' must be a symbol but was a '#{value.class}'")
      end
    end
    
  end

  ##
  #
  class JabaAttributeTypeSymbolOrString < JabaAttributeType
    
    ##
    #
    def initialize
      super(:symbol_or_string, 'Symbol or string attribute type')
      @notes = 'Only explicit strings or symbols will be accepted'
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.symbol? && !value.string?
        JABA.error("'#{value}' must be a symbol or a string but was a '#{value.class}'")
      end
    end
    
  end

    ##
  #
  class JabaAttributeTypeToS < JabaAttributeType
    
    ##
    #
    def initialize
      super(:to_s, 'to_s attribute type')
      @notes = 'Any object that supports that can be converted to a string with to_s will be accepted. This is very permissive as ' \
      'in practice this is just about anything in ruby - this type is here to make that intention explcit.'
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.respond_to?(:to_s)
        JABA.error("'#{value}' must respond to 'to_s' method but '#{value.class}' did not")
      end
    end
    
  end

  ##
  #
  class JabaAttributeTypeInt < JabaAttributeType
  
    ##
    #
    def initialize
      super(:int, 'Integer attribute type', default: 0)
      @notes = 'Defaults to 0 unless value must be specified by user'
    end

    ##
    #
    def from_cmdline(str, attr_def)
      begin
        Integer(str)
      rescue
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - integer expected", want_backtrace: false)
      end
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.integer?
        JABA.error(":int attributes only accept integer values but got [value=#{value}, class=#{value.class}]")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeBool < JabaAttributeType
    
    ##
    #
    def initialize
      super(:bool, 'Boolean attribute type', default: false)
      @notes = 'Accepts [true|false]. Defaults to false unless value must be supplied by user.'
    end

    ##
    #
    def from_cmdline(str, attr_def)
      case str
      when 'true', '1'
        true
      when 'false', '0'
        false
      else
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - [true|false|0|1] expected", want_backtrace: false)
      end
    end

    ##
    #
    def post_init_attr_def(attr_def)
      if attr_def.array?
        attr_def.set_property(:flags, [:no_sort, :allow_dupes])
      end
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.boolean?
        JABA.error(":bool attributes only accept [true|false] but got '#{value}'")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeChoice < JabaAttributeType
    
    ##
    #
    def initialize
      super(:choice, 'Choice attribute type')
      @notes = 'Can take exactly one of a set of unique values'
    end

    ##
    #
    def from_cmdline(str, attr_def)
      items = attr_def.items
      
      # Use find_index to allow for nil being a valid choice
      #
      index = items.find_index{|i| i.to_s == str}
      if index.nil?
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - [#{items.map{|i| i.to_s}.join('|')}] expected", want_backtrace: false)
      end
      items[index]
    end

    ##
    #
    def get_reference_manual_rows(attr_def)
      { items: attr_def.items.inspect }
    end
    
    ##
    #
    def init_attr_def(attr_def)
      attr_def.define_array_property(:items)
    end

    ##
    #
    def post_init_attr_def(attr_def)
      items = attr_def.items
      if items.empty?
        JABA.error("'items' must be set")
      elsif items.uniq!
        services.jaba_warn("'items' contains duplicates")
      end
    end

    ##
    #
    def validate_value(attr_def, value)
      items = attr_def.items
      if !items.include?(value)
        JABA.error("Must be one of #{items} but got '#{value}'")
      end
    end

  end

  ##
  #
  class PathAttrBase < JabaAttributeType

    ##
    # Used when converting a path specified in jaba definitions into an absolute path.
    #
    VALID_BASE_SPECS = [
      :cwd,               # path will be based on current working directory (the directory jaba was invoked in)
      :definition_root,   # path will be based on the specified root of the jaba definition the path was set in
      :build_root,        # path will be based on build_root
      :jaba_file          # path will be based on the directory of the jaba definition file the path was set in
    ]
    
    ##
    #
    def init_attr_def(attr_def)
      attr_def.define_property(:basedir_spec)
    end

    ##
    #
    def post_init_attr_def(attr_def)
      if !VALID_BASE_SPECS.include?(attr_def.basedir_spec)
        JABA.error("'basedir_spec' must be one of #{VALID_BASE_SPECS}")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeFile < PathAttrBase
    
    ##
    #
    def initialize
      super(:file, 'File attribute type')
      @notes = 'Validates that value is a string path representing a file'
    end

    ##
    #
    def validate_value(attr_def, file)
      file.validate_path do |msg|
        services.jaba_warn("File '#{file}' not specified cleanly: #{msg}")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeDir < PathAttrBase
    
    ##
    #
    def initialize
      super(:dir, 'Directory attribute type', default: '.')
      @notes = 'Validates that value is a string path representing a directory'
    end

    ##
    #
    def validate_value(attr_def, dir)
      dir.validate_path do |msg|
        services.jaba_warn("Directory '#{dir}' not specified cleanly: #{msg}")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeSrcSpec < PathAttrBase
    
    ##
    #
    def initialize
      super(:src_spec, 'Source file specification pattern')
      @notes = 'Can be file glob match an explicit path or a directory'
    end

    ##
    #
    def validate_value(attr_def, src_spec)
      src_spec.validate_path do |msg|
        services.jaba_warn("Src spec '#{src_spec}' not specified cleanly: #{msg}")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeUUID < JabaAttributeType
    
    ##
    #
    def initialize
      super(:uuid, 'UUID attribute type')
    end

    ##
    #
    def map_value(value)
      JABA.generate_guid(namespace: 'JabaAttributeTypeUUID', name: value)
    end

  end

  ##
  #
  class JabaAttributeTypeNodeRef < JabaAttributeType
    
    ##
    #
    def initialize
      super(:node_ref, 'Node reference attribute type')
    end

    ##
    #
    def get_reference_manual_rows(attr_def)
      { node_type: attr_def.node_type.inspect }
    end

    ##
    #
    def init_attr_def(attr_def)
      attr_def.define_property(:node_type)
      attr_def.define_block_property(:make_handle)
      attr_def.define_block_property(:unresolved_msg)
    end

    ##
    #
    def post_init_attr_def(attr_def)
      t = attr_def.node_type
      if t.nil?
        JABA.error("'node_type' must be set")
      end
      if attr_def.jaba_type.defn_id != t
        attr_def.jaba_type.top_level_type.set_property(:dependencies, t)
      end
    end

  end

  ##
  #
  class JabaAttributeTypeNode < JabaAttributeType
    
    ##
    #
    def initialize
      super(:node, 'Node attribute type')
    end

    ##
    #
    def get_reference_manual_rows(attr_def)
      { node_type: attr_def.node_type.inspect }
    end

    ##
    #
    def init_attr_def(attr_def)
      attr_def.define_property(:node_type)
    end

    ##
    #
    def post_init_attr_def(attr_def)
      t = attr_def.node_type
      if t.nil?
        JABA.error("'node_type' must be set")
      end
      if attr_def.jaba_type.defn_id == t
        JABA.error("node_type attribute cannot be set to owning type")
      else
        attr_def.jaba_type.top_level_type.set_property(:dependencies, t)
      end
    end

  end

end
