# frozen_string_literal: true

module JABA

  ##
  #
  class JabaAttributeTypeAPI < BasicObject

    include APICommon

    ##
    #
    def init_attr_def(&block)
      @attr_type.define_hook(:init_attr_def, &block)
    end
    
    ##
    #
    def validate_attr_def(&block)
      @attr_type.define_hook(:validate_attr_def, &block)
    end
    
    ##
    #
    def validate_value(&block)
      @attr_type.define_hook(:validate_value, &block)
    end

    ##
    #
    def initialize(attr_type)
      @attr_type = @obj = attr_type
    end

  end

end
