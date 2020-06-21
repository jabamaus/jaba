# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType
    
    attr_reader :services

    ##
    #
    def id
    end

    ##
    #
    def title
    end

    ##
    #
    def help
    end

    ##
    #
    def default
    end

    ##
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
    def id
      :string
    end

    ##
    #
    def title
      'String attribute type'
    end

    ##
    #
    def help
      'Only explicit strings will be accepted. Symbols are not valid.'
    end

    ##
    #
    def default
      ''
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.string?
        services.jaba_error("'#{value}' must be a string but was a '#{value.class}'")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeSymbol < JabaAttributeType
    
    ##
    #
    def id
      :symbol
    end

    ##
    #
    def title
      'Symbol attribute type'
    end

    ##
    #
    def help
      'Only explicit symbols will be accepted. Strings are not valid.'
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.symbol?
        services.jaba_error("'#{value}' must be a symbol but was a '#{value.class}'")
      end
    end
    
  end

  ##
  #
  class JabaAttributeTypeSymbolOrString < JabaAttributeType
    
    ##
    #
    def id
      :symbol_or_string
    end

    ##
    #
    def title
      'Symbol or string attribute type'
    end

    ##
    #
    def help
      'Only explicit strings or symbols will be accepted'
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.symbol? && !value.string?
        services.jaba_error("'#{value}' must be a symbol or a string but was a '#{value.class}'")
      end
    end
    
  end

  ##
  #
  class JabaAttributeTypeBool < JabaAttributeType
    
    ##
    #
    def id
      :bool
    end

    ##
    #
    def title
      'Boolean attribute type'
    end

    ##
    #
    def help
      'Accepts [true|false]. Defaults to false'
    end

    ##
    #
    def default
      false
    end

    ##
    #
    def post_init_attr_def(attr_def)
      if attr_def.attr_array?
        attr_def.set_property(:flags, [:nosort, :allow_dupes])
      end
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.boolean?
        services.jaba_error(":bool attributes only accept [true|false] but got '#{value}'")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeChoice < JabaAttributeType
    
    ##
    #
    def id
      :choice
    end

    ##
    #
    def title
      'Choice attribute type'
    end

    ##
    #
    def help
      'Can take exactly one of a set of unique values'
    end

    ##
    #
    def init_attr_def(attr_def)
      attr_def.define_array_property(:items)
    end

    ##
    #
    def post_init_attr_def(attr_def)
      items = attr_def.get_property(:items)
      if items.empty?
        services.jaba_error("'items' must be set")
      elsif items.uniq!
        services.jaba_warning("'items' contains duplicates")
      end
    end

    ##
    #
    def validate_value(attr_def, value)
      items = attr_def.get_property(:items)
      if !items.include?(value)
        services.jaba_error("must be one of #{items} but was '#{value}'")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeFile < JabaAttributeType
    
    ##
    #
    def id
      :file
    end

    ##
    #
    def title
      'File attribute type'
    end

    ##
    #
    def help
      'Validates that value is a string path representing a file'
    end

    ##
    #
    def validate_value(attr_def, file)
      file.cleanpath(validate: true) do |clean|
        services.jaba_warning("File '#{file}' not specified cleanly. Should be '#{clean}'.")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeDir < JabaAttributeType
    
    ##
    #
    def id
      :dir
    end

    ##
    #
    def title
      'Directory attribute type'
    end

    ##
    #
    def help
      'Validates that value is a string path representing a directory'
    end

    ##
    #
    def validate_value(attr_def, dir)
      dir.cleanpath(validate: true) do |clean|
        services.jaba_warning("Directory '#{dir}' not specified cleanly. Should be '#{clean}'.")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeSrcSpec < JabaAttributeType
    
    ##
    #
    def id
      :src_spec
    end

    ##
    #
    def title
      'Source file specification pattern'
    end

    ##
    #
    def help
      'Can be file glob match an explicit path or a directory'
    end

    ##
    #
    def validate_value(attr_def, src_spec)
      src_spec.cleanpath(validate: true) do |clean|
        services.jaba_warning("Src spec '#{src_spec}' not specified cleanly. Should be '#{clean}'.")
      end
    end

  end

  ##
  #
  class JabaAttributeTypeUUID < JabaAttributeType
    
    ##
    #
    def id
      :uuid
    end

    ##
    #
    def title
      'UUID attribute type'
    end

    ##
    #
    def help
      'TODO'
    end

    ##
    #
    def validate_value(attr_def, uuid)
      if uuid !~ /[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/
        services.jaba_error('Must be an all upper case GUID in the form 0376E589-F783-4B80-DA86-705F2E05304E')
      end
    end

  end

  ##
  #
  class JabaAttributeTypeReference < JabaAttributeType
    
    ##
    #
    def id
      :reference
    end

    ##
    #
    def title
      'Reference attribute type'
    end

    ##
    #
    def help
      'TODO'
    end

    ##
    # TODO: remove. Do in core to save all the property setting and getting
    def init_attr_def(attr_def)
      attr_def.define_property(:referenced_type)
      attr_def.define_property(:make_handle) # TODO: flag as block or validate as such
    end

    ##
    #
    def post_init_attr_def(attr_def)
      rt = attr_def.get_property(:referenced_type)
      if rt.nil?
        services.jaba_error("'referenced_type' must be set")
      end
      if attr_def.jaba_type.defn_id != rt
        attr_def.jaba_type.top_level_type.set_property(:dependencies, rt)
      end
    end

  end

end
