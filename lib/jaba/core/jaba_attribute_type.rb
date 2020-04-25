# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType < JabaObject

    include PropertyMethods
    
    ##
    #
    def initialize(services, def_block)
      super(services, def_block, JabaAttributeTypeAPI.new(self))
     
      define_property(:help)
      define_hook(:init_attr_def)
      define_hook(:validate_attr_def)
      define_hook(:validate_value)

      if def_block.block
        eval_api_block(&def_block.block)
      end
    end

  end

end
