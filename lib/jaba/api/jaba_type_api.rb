# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class JabaTypeAPI < BasicObject

    include APICommon

    ##
    # Define a new attribute.
    #
    def attr(id, **options, &block)
      @jaba_type.define_attr(id, :single, **options, &block)
    end
    
    ##
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
      @jaba_type.type
    end

    ##
    #
    def initialize(jaba_type)
      @jaba_type = @obj = jaba_type
    end

  end

end
