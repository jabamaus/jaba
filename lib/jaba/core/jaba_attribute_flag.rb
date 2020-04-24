# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeFlag < JabaObject
  
    include PropertyMethods

    ##
    #
    def initialize(services, def_block)
      super(services, def_block.definition_id, JabaAttributeFlagAPI.new(self))

      define_property(:help)

      if def_block.block
        eval_api_block(&def_block.block)
      end
    end

  end

end
