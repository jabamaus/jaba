# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType < JabaObject

    attr_reader :type # eg :bool, :choice, :keyvalue
    attr_reader :init_attr_def_hook
    attr_reader :validate_attr_def_hook
    attr_reader :validate_value_hook
    
    ##
    #
    def initialize(services, info)
      super(services, JabaAttributeTypeAPI.new(self))
      @type = info.type
      @init_attr_def_hook = nil
      @validate_attr_def_hook = nil
      @validate_value_hook = nil
      eval_definition(&info.block) if info.block
    end

  end

end
