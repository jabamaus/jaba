# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeFlag < JDL_Object
  
    include PropertyMethods

    ##
    #
    def initialize(definition)
      super(definition, JDL_AttributeFlag.new(self))

      define_array_property(:help)
      define_hook(:compatibility)

      if definition.block
        eval_jdl(&definition.block)
      end
    end

    ##
    # Used in error messages.
    #
    def describe
      "':#{@defn_id}' flag"
    end

  end

end
