module JABA

  ##
  #
  class JabaAttributeTypeAPI < BasicObject

    include APICommon

    ##
    # Set help for the attribute type. Required.
    #
    def help(val = nil, &block)
      @attr_type.set_property(:help, val, &block)
    end

    ##
    #
    def init_attr_def(&block)
      @attr_type.set_hook(:init_attr_def, &block)
    end
    
    ##
    #
    def post_init_attr_def(&block)
      @attr_type.set_hook(:post_init_attr_def, &block)
    end
    
    ##
    #
    def validate_value(&block)
      @attr_type.set_hook(:validate_value, &block)
    end

    private
  
    ##
    #
    def initialize(attr_type)
      @attr_type = @obj = attr_type
    end

  end

end
