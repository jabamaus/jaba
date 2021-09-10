module JABA

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

    ##
    #
    def raise_type_error(value, expected)
      value_class = value.class
      if value_class == TrueClass || value_class == FalseClass
        value_class = 'boolean'
      end
      JABA.error("'#{value.inspect_unquoted}' is a #{value_class.to_s.downcase} but expected #{expected}")
    end

  end

  ##
  #
  class JabaAttributeTypeString < JabaAttributeType
    
    def initialize
      super(:string, 'String attribute type', default: '')
      @notes = 'Only explicit strings will be accepted. Symbols are not valid. Defaults to empty string unless value must be specified by user.'
    end

    def validate_value(attr_def, value)
      if !value.string?
        raise_type_error(value, 'a string')
      end
    end

  end

  ##
  #
  class JabaAttributeTypeSymbol < JabaAttributeType
    
    def initialize
      super(:symbol, 'Symbol attribute type')
      @notes = 'Only explicit symbols will be accepted. Strings are not valid.'
    end

    def from_cmdline(str, attr_def)
      str.to_sym
    end

    def validate_value(attr_def, value)
      if !value.symbol?
        raise_type_error(value, 'a symbol')
      end
    end
    
  end

  ##
  #
  class JabaAttributeTypeSymbolOrString < JabaAttributeType
    
    def initialize
      super(:symbol_or_string, 'Symbol or string attribute type')
      @notes = 'Only explicit strings or symbols will be accepted'
    end

    def validate_value(attr_def, value)
      if !value.symbol? && !value.string?
        raise_type_error(value, 'a symbol or a string')
      end
    end
    
  end

  ##
  #
  class JabaAttributeTypeToS < JabaAttributeType
    
    def initialize
      super(:to_s, 'to_s attribute type')
      @notes = 'Any object that supports that can be converted to a string with to_s will be accepted. This is very permissive as ' \
      'in practice this is just about anything in ruby - this type is here to make that intention explcit.'
    end

    def validate_value(attr_def, value)
      if !value.respond_to?(:to_s)
        JABA.error("'#{value}' must respond to 'to_s' method but '#{value.class}' did not")
      end
    end
    
  end

  ##
  #
  class JabaAttributeTypeInt < JabaAttributeType
  
    def initialize
      super(:int, 'Integer attribute type', default: 0)
      @notes = 'Defaults to 0 unless value must be specified by user'
    end

    def from_cmdline(str, attr_def)
      begin
        Integer(str)
      rescue
        JABA.error("'#{str}' invalid value for #{attr_def.describe} - integer expected", want_backtrace: false)
      end
    end

    def validate_value(attr_def, value)
      if !value.integer?
        raise_type_error(value, 'an integer')
      end
    end

  end

  ##
  #
  class JabaAttributeTypeBool < JabaAttributeType
    
    def initialize
      super(:bool, 'Boolean attribute type', default: false)
      @notes = 'Accepts [true|false]. Defaults to false unless value must be supplied by user.'
    end

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

    def post_init_attr_def(attr_def)
      if attr_def.array?
        attr_def.set_property(:flags, [:no_sort, :allow_dupes])
      end
    end

    def validate_value(attr_def, value)
      if !value.boolean?
        raise_type_error(value, "'true' or 'false'")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeChoice < JabaAttributeType
    
    def initialize
      super(:choice, 'Choice attribute type')
      @notes = 'Can take exactly one of a set of unique values'
    end

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

    def get_reference_manual_rows(attr_def)
      { choices: attr_def.items.inspect }
    end
    
    def init_attr_def(attr_def)
      attr_def.define_array_property(:items)
    end

    def post_init_attr_def(attr_def)
      items = attr_def.items
      if items.empty?
        attr_def.property_validation_error(:items, "'items' must be set")
      elsif items.uniq!
        attr_def.property_validation_warning(:items, "'items' contains duplicates")
      end
    end

    def validate_value(attr_def, value)
      items = attr_def.items
      if !items.include?(value)
        JABA.error("Must be one of #{items} but got '#{value.inspect_unquoted}'. See #{attr_def.property_last_call_loc(:items).describe}.")
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
      :buildsystem_root,  # path will be based on buildsystem (itself based on build_root)
      :artefact_root,     # path will be based on build artefact root
      :jaba_file          # path will be based on the directory of the jaba definition file the path was set in
    ]
    
    def init_attr_def(attr_def)
      attr_def.define_property(:basedir_spec)
    end

    def post_init_attr_def(attr_def)
      if !VALID_BASE_SPECS.include?(attr_def.basedir_spec)
        attr_def.property_validation_error(:basedir_spec, "'basedir_spec' must be one of #{VALID_BASE_SPECS}")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeFile < PathAttrBase
    
    def initialize
      super(:file, 'File attribute type')
      @notes = 'Validates that value is a string path representing a file'
    end

    def validate_value(attr_def, file)
      file.validate_path do |msg|
        services.jaba_warn("File '#{file}' not specified cleanly: #{msg}")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeDir < PathAttrBase
    
    def initialize
      super(:dir, 'Directory attribute type', default: '.')
      @notes = 'Validates that value is a string path representing a directory'
    end

    def validate_value(attr_def, dir)
      dir.validate_path do |msg|
        services.jaba_warn("Directory '#{dir}' not specified cleanly: #{msg}")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeSrcSpec < PathAttrBase
    
    def initialize
      super(:src_spec, 'Source file specification pattern')
      @notes = 'Can be file glob match an explicit path or a directory'
    end

    def validate_value(attr_def, src_spec)
      src_spec.validate_path do |msg|
        services.jaba_warn("Src spec '#{src_spec}' not specified cleanly: #{msg}")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeBasename < JabaAttributeType
  
    def initialize
      super(:basename, 'basename attribute type')
      @notes = 'Basename of a file. Slashes are rejected.'
    end

    def validate_value(attr_def, value)
      if value.contains_slashes?
        JABA.error("'#{value}' must not contain slashes")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeUUID < JabaAttributeType
    
    def initialize
      super(:uuid, 'UUID attribute type')
    end

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
      super(:ref, 'Node reference attribute type')
    end

    def get_reference_manual_rows(attr_def)
      ref_type = services.get_jaba_type(attr_def.ref_jaba_type)
      { references: "[#{attr_def.ref_jaba_type}](#{ref_type.reference_manual_page})" }
    end

    def init_attr_def(attr_def)
      attr_def.define_block_property(:make_handle)
      attr_def.define_block_property(:unresolved_msg)
    end

  end

  ##
  #
  class JabaAttributeTypeNode < JabaAttributeType
    
    def initialize
      super(:node, 'Node attribute type')
    end

    def get_reference_manual_rows(attr_def)
      ref_type = services.get_jaba_type(attr_def.ref_jaba_type)
      { node_type: "[#{attr_def.ref_jaba_type}](#{ref_type.reference_manual_page})" }
    end

  end

  class JabaAttributeTypeBlock < JabaAttributeType
    
    def initialize
      super(:block, 'Block attribute type')
    end

    def from_cmdline(str, attr_def)
      JABA.error("block attributes cannot be specified on command line")
    end

    def post_init_attr_def(attr_def)
      if attr_def.array?
        attr_def.set_property(:flags, [:no_sort, :allow_dupes])
      end
    end

    def validate_value(attr_def, value)
      JABA.error("must be a block") if !value.proc?
    end

  end

end
