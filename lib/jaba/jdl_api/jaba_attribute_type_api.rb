module JABA

  ##
  #
  class JDL_AttributeType < BasicObject

    include JDL_Common

    ##
    # Set title of attribute type
    #
    def title(val = nil)
      @attr_type.set_property(:title, val)
    end

    ##
    # Set help for the attribute type. Required.
    #
    def help(val)
      @attr_type.set_property(:help, val)
    end

    ##
    #
    def default(val)
      @attr_type.set_property(:default, val)
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
