# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeFlag < JabaObject
  
    include PropertyMethods

    ##
    #
    def initialize(services, info)
      super(services, info.definition_id, JabaAttributeFlagAPI.new(self))

      define_property(:help)

      if info.block
        eval_api_block(&info.block)
      end
    end

  end

end
