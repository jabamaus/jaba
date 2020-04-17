module  JABA

  ##
  # API that is common to all public facing definitions. Not accessible from internal objects.
  #
  module APICommon

    ##
    #
    def fail(msg)
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

    ##
    # For debugging.
    #
    def to_s
      @obj.to_s
    end

  end

end
