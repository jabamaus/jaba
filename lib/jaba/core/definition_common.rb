# frozen_string_literal: true

module  JABA

  using JABACoreExt
  
  ##
  # API that is common to all public facing definitions. Not accessible from internal objects.
  #
  module DefinitionCommon

    ##
    #
    def raise(msg)
      @obj.jaba_error(msg)
    end

    ##
    #
    def print(msg)
      ::Kernel.print(msg)
    end

    ##
    #
    def include(*shared_definition_ids, args: nil)
      @obj.include_shared(shared_definition_ids, args)
    end

  end

end