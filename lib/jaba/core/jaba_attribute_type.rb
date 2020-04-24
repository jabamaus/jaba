# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType < JabaObject

    include PropertyMethods
    
    ##
    #
    def initialize(services, info)
      super(services, info.definition_id, JabaAttributeTypeAPI.new(self))
     
      define_property(:help)
      define_hook(:init_attr_def)
      define_hook(:validate_attr_def)
      define_hook(:validate_value)

      if info.block
        eval_api_block(&info.block)
      end
    end

    ##
    #
    def to_s
      @definition_id.to_s
    end

  end

end
