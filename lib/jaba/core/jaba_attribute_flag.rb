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
      super(services, JabaAttributeFlagAPI.new(self))

      @id = info.id
      @help = nil

      if info.block
        eval_api_block(&info.block)
      end
    end

  end

end
