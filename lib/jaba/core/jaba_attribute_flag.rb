# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeFlag < JabaObject
  
    include PropertyMethods

    ##
    #
    def initialize(services, definition)
      super(services, definition, JabaAttributeFlagAPI.new(self))

      define_property(:help)

      if definition.block
        eval_api_block(&definition.block)
      end
    end

  end

end
