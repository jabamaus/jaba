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
      @attr_def.set_property(:flags, flags.flatten, &block)
    end
    
    ##
    # Set attribute default value. Can be specified as a value or a block.
    #
    def default(val = nil, &block)
      @attr_def.set_property(:default, val, &block)
    end
    
    ##
    #
    def keyval_options(*options, &block)
      @attr_def.set_property(:keyval_opts, options.flatten, &block)
    end
    
    ##
    # Called for single value attributes and each element of array attributes.
    #
    def validate(&block)
      @attr_def.define_hook(:validate, &block)
    end
    
    ##
    #
    def post_set(&block)
      @attr_def.define_hook(:post_set, &block)
    end
    
    ##
    #
    def make_handle(&block)
      @attr_def.define_hook(:make_handle, &block)
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

  private
  
    ##
    #
    def method_missing(id, val = nil)
      @attr_def.handle_property(id, val)
    end

    ##
    #
    def initialize(attr_def)
      @attr_def = @obj = attr_def
    end
    
  end

end
