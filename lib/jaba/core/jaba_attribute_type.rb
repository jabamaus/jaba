# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType < JabaObject

    attr_reader :type_id # eg :bool, :choice, :keyvalue
    attr_reader :init_attr_def_hook
    attr_reader :validate_attr_def_hook
    attr_reader :validate_value_hook
    
    ##
    #
    def initialize(services, info)
      super(services, JabaAttributeTypeAPI.new(self))
      @type_id = info.type_id
      @init_attr_def_hook = nil
      @validate_attr_def_hook = nil
      @validate_value_hook = nil
      eval_api_block(&info.block) if info.block
    end

    ##
    # For ease of debugging.
    #
    def to_s
      @type_id.to_s
    end

  end

end
