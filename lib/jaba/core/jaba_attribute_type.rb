# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType < JabaObject

    attr_reader :type
    attr_reader :init_attr_def_hook
    attr_reader :validate_attr_def_hook
    attr_reader :validate_value_hook
    
    ##
    #
    def initialize(services, info)
      super(services)
      @type = info.type
      @init_attr_def_hook = nil
      @validate_attr_def_hook = nil
      @validate_value_hook = nil
      @definition_interface = JabaAttributeTypeAPI.new(self)
      eval_definition(&info.block) if info.block
    end

    ##
    #
    def eval_obj(context)
      @definition_interface
    end

  end

end
