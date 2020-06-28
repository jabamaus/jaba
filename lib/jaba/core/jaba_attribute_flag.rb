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

      define_property(:title)
      define_array_property(:notes)
      define_array_property(:examples)
      define_hook(:compatibility)

      if definition.block
        eval_jdl(&definition.block)
      end

      # TODO: validate title supplied
      @title.freeze
      @notes.freeze
      @examples.freeze
    end

    ##
    # Used in error messages.
    #
    def describe
      "':#{@defn_id}' flag"
    end

  end

end
