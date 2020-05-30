module  JABA

  ##
  # API that is common to all public facing definitions.
  #
  module APICommon

    ##
    #
    def fail(msg)
      @obj.jaba_error(msg)
    end

    ##
    #
    def warn(msg)
      @obj.jaba_warning(msg)
    end

    ##
    #
    def print(msg)
      ::Kernel.print(msg)
    end

    ##
    #
    def puts(msg)
      ::Kernel.puts(msg)
    end

    ##
    #
    def _ID
      @obj.definition.id
    end

    ##
    #
    def include(shared_definition_id, args: nil)
      @obj.include_shared(shared_definition_id, args)
    end

    ##
    # Returns all the ids of all defined instances of the given type. Can be useful when populating choice attribute items.
    # The type must be defined before this is called, which can be achieved by adding a dependency.
    #
    def all_instance_ids(jaba_type_id)
      @obj.services.get_instance_ids(jaba_type_id)
    end

    ##
    # For debugging.
    #
    def to_s
      @obj.to_s
    end

  end

end
