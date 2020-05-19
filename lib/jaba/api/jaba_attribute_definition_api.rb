module JABA

  ##
  #
  class JabaAttributeDefinitionAPI < BasicObject

    include APICommon

    ##
    # Set help for the attribute. Required.
    #
    def help(val = nil, &block)
      @attr_def.set_property(:help, val, &block)
    end
    
    ##
    # Set any number of flags to control the behaviour of the attribute.
    #
    def flags(*flags, &block)
      @attr_def.set_property(:flags, flags, &block)
    end
    
    ##
    # Set attribute default value. Can be specified as a value or a block.
    #
    def default(val = nil, &block)
      @attr_def.set_property(:default, val, &block)
    end
    
    ##
    #
    def flag_options(*options, &block)
      @attr_def.set_property(:flag_options, options, &block)
    end

    ##
    # Specify an option that takes a value.
    #
    # attr :myattr do
    #   value_option :group, required: true, items [:a, :b, :c]
    # end
    # 
    # would be called like this in definitions:
    #
    # myattr 'value', group: :a
    #
    # And the presence of the :group option and its value would be validated.
    #
    def value_option(id, required: false, items: [], &block)
      @attr_def.add_value_option(id, required, items, &block)
    end
    
    ##
    # Called for single value attributes and each element of array attributes.
    #
    def validate(&block)
      @attr_def.set_hook(:validate, &block)
    end
    
    ##
    #
    def define_property(id, val = nil)
      @attr_def.define_property(id, val)
    end

    ##
    #
    def define_array_property(id, val = [])
      @attr_def.define_array_property(id, val)
    end

    ##
    #
    def jaba_type
      @attr_def.jaba_type.api
    end

    ##
    #
    def method_missing(id, val = nil, &block)
      @attr_def.handle_property(id, val, &block)
    end
    
    private
  
    ##
    #
    def initialize(attr_def)
      @attr_def = @obj = attr_def
    end
    
  end

end
