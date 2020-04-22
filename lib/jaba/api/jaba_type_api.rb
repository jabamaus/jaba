##
#
module JABA

  ##
  #
  class JabaTypeAPI < BasicObject

    include APICommon

    ##
    # Set help for the type. Required.
    #
    def help(val = nil, &block)
      @jaba_type.set_property(:help, val, &block)
    end

    ##
    # Define a new attribute.
    #
    def attr(id, **options, &block)
      @jaba_type.define_attr(id, :single, **options, &block)
    end
    
    ##
    # Define a new array attribute.
    #
    def attr_array(id, **options, &block)
      @jaba_type.define_attr(id, :array, **options, &block)
    end
    
    ##
    #
    def dependencies(*deps)
      @jaba_type.set_property(:dependencies, deps.flatten)
    end

    ##
    #
    def type
      @jaba_type.type_id
    end

  private
  
    ##
    #
    def initialize(jaba_type)
      @jaba_type = @obj = jaba_type
    end

  end

end
