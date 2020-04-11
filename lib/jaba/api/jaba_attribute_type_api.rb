# frozen_string_literal: true

module JABA

  ##
  #
  class JabaAttributeTypeAPI < BasicObject

    include APICommon

    ##
    #
    def init_attr_def(&block)
      @attr_type_def.define_hook(:init_attr_def, &block)
    end
    
    ##
    #
    def validate_attr_def(&block)
      @attr_type_def.define_hook(:validate_attr_def, &block)
    end
    
    ##
    #
    def validate_value(&block)
      @attr_type_def.define_hook(:validate_value, &block)
    end

    ##
    #
    def initialize(attr_type_def)
      @attr_type_def = attr_type_def
      @obj = attr_type_def
    end

  end

end
