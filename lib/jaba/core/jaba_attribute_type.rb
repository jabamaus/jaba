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
    def notes
    end

    ##
    #
    def default
    end

    ##
    #
    def from_string(str)
      raise "from_string(str) must be implemented in #{self.class}"
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
    def map_value(value)
      value
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
    def notes
      'Only explicit strings will be accepted. Symbols are not valid. Defaults to empty string unless value must be specified by user.'
    end

    ##
    #
    def default
      ''
    end

    ##
    #
    def from_string(str)
      str
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
    def notes
      'Only explicit symbols will be accepted. Strings are not valid.'
    end

    ##
    #
    def from_string(str)
      str.to_sym
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
    def notes
      'Only explicit strings or symbols will be accepted'
    end

    ##
    #
    def from_string(str)
      str
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
  class JabaAttributeTypeToS < JabaAttributeType
    
    ##
    #
    def id
      :to_s
    end

    ##
    #
    def title
      'to_s attribute type'
    end

    ##
    #
    def notes
      'Any object that supports that can be converted to a string with to_s will be accepted. This is very permissive as ' \
      'in practice this is just about anything in ruby - this type is here to make that intention explcit.'
    end

    ##
    #
    def from_string(str)
      str
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.respond_to?(:to_s)
        services.jaba_error("'#{value}' must respond to 'to_s' method but '#{value.class}' did not")
      end
    end
    
  end

  ##
  #
  class JabaAttributeTypeInt < JabaAttributeType
  
    ##
    #
    def id
      :int
    end

    ##
    #
    def title
      'Integer attribute type'
    end

    ##
    #
    def notes
      'Defaults to 0 unless value must be specified by user'
    end
    
    ##
    #
    def default
      0
    end

    ##
    #
    def from_string(str)
      str.to_i
    end

    ##
    #
    def validate_value(attr_def, value)
      if !value.integer?
        services.jaba_error(":int attributes only accept integer values but got [value=#{value}, class=#{value.class}]")
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
    def notes
      'Accepts [true|false]. Defaults to false unless value must be supplied by user.'
    end

    ##
    #
    def default
      false
    end

    ##
    #
    def from_string(str)
      case str
      when 'true'
        true
      when 'false'
        false
      else
        services.jaba_error("Invalid value '#{str}' passed to JabaAttributeTypeBool#from_string")
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
    def notes
      'Can take exactly one of a set of unique values'
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
    def from_string(str)
      str
    end

    ##
    #
    def post_init_attr_def(attr_def)
      items = attr_def.items
      if items.empty?
        services.jaba_error("'items' must be set")
      elsif items.uniq!
        services.jaba_warning("'items' contains duplicates")
      end
    end

    ##
    #
    def validate_value(attr_def, value)
      items = attr_def.items
      if !items.include?(value)
        services.jaba_error("Must be one of #{items} but got '#{value}'")
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
    def notes
      'Validates that value is a string path representing a file'
    end

    ##
    #
    def from_string(str)
      str
    end

    ##
    #
    def validate_value(attr_def, file)
      file.validate_path do |msg|
        services.jaba_warning("File '#{file}' not specified cleanly: #{msg}")
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
    def notes
      'Validates that value is a string path representing a directory'
    end

    ##
    #
    def default
      '.'
    end

    ##
    #
    def from_string(str)
      str
    end

    ##
    #
    def validate_value(attr_def, dir)
      dir.validate_path do |msg|
        services.jaba_warning("Directory '#{dir}' not specified cleanly: #{msg}")
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
    def notes
      'Can be file glob match an explicit path or a directory'
    end

    ##
    #
    def from_string(str)
      str
    end

    ##
    #
    def validate_value(attr_def, src_spec)
      src_spec.validate_path do |msg|
        services.jaba_warning("Src spec '#{src_spec}' not specified cleanly: #{msg}")
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
    def notes
      'TODO'
    end

    ##
    #
    def from_string(str)
      str
    end

    ##
    #
    def map_value(value)
      JABA.generate_guid(namespace: 'JabaAttributeTypeUUID', name: value)
    end

  end

  ##
  #
  class JabaAttributeTypeObjectRef < JabaAttributeType
    
    ##
    #
    def id
      :object_ref
    end

    ##
    #
    def title
      'Object reference attribute type'
    end

    ##
    #
    def notes
      'TODO'
    end

    ##
    #
    def from_string(str)
      str
    end

    ##
    #
    def get_reference_manual_rows(attr_def)
      { object_type: attr_def.object_type.inspect }
    end

    ##
    # TODO: remove. Do in core to save all the property setting and getting
    def init_attr_def(attr_def)
      attr_def.define_property(:object_type)
      attr_def.define_property(:make_handle) # TODO: flag as block or validate as such
    end

    ##
    #
    def post_init_attr_def(attr_def)
      t = attr_def.object_type
      if t.nil?
        services.jaba_error("'object_type' must be set")
      end
      if attr_def.jaba_type.defn_id != t
        attr_def.jaba_type.top_level_type.set_property(:dependencies, t)
      end
    end

  end

  ##
  #
  class JabaAttributeTypeObject < JabaAttributeType
    
    ##
    #
    def id
      :object
    end

    ##
    #
    def title
      'Object attribute type'
    end

    ##
    #
    def notes
      'TODO'
    end

    ##
    #
    def from_string(str)
      str
    end

    ##
    #
    def get_reference_manual_rows(attr_def)
      { object_type: attr_def.object_type.inspect }
    end

    ##
    #
    def init_attr_def(attr_def)
      attr_def.define_property(:object_type)
    end

    ##
    #
    def post_init_attr_def(attr_def)
      t = attr_def.object_type
      if t.nil?
        services.jaba_error("'object_type' must be set")
      end
      if attr_def.jaba_type.defn_id == t
        services.jaba_error("object_type attribute cannot be set to owning type")
      else
        attr_def.jaba_type.top_level_type.set_property(:dependencies, t)
      end
    end

  end

end
