# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType < JDL_Object

    include PropertyMethods

    attr_reader :default
    
    ##
    #
    def initialize(definition)
      super(definition, JDL_AttributeType.new(self))
     
      define_property(:title)
      define_property(:help)
      define_property(:default)
      define_hook(:init_attr_def)
      define_hook(:post_init_attr_def)
      define_hook(:validate_value)

      if definition.block
        eval_jdl(&definition.block)
      end
    end

  end

end
