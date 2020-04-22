# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType < JabaObject

    include PropertyMethods
    
    attr_reader :type_id # eg :bool, :choice, :keyvalue
    
    ##
    #
    def initialize(services, info)
      super(services, JabaAttributeTypeAPI.new(self))
      @type_id = info.type_id
      
      define_property(:help)
      define_hook(:init_attr_def)
      define_hook(:validate_attr_def)
      define_hook(:validate_value)

      if info.block
        eval_api_block(&info.block)
      end
    end

    ##
    # For ease of debugging.
    #
    def to_s
      @type_id.to_s
    end

  end

end
