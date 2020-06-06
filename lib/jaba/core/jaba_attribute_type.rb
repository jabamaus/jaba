# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeType < JabaObject

    include PropertyMethods

    attr_reader :default
    
    ##
    #
    def initialize(services, definition)
      super(services, definition, JabaAttributeTypeAPI.new(self))
     
      define_property(:title)
      define_property(:help)
      define_property(:default)
      define_hook(:init_attr_def)
      define_hook(:post_init_attr_def)
      define_hook(:validate_value)

      if definition.block
        eval_api_block(&definition.block)
      end
    end

  end

end
