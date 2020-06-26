module JABA

  ##
  #
  class JDL_Node < BasicObject

    include JDL_Common

    ##
    # Clears any previously set values. Sets single attribute values to nil and clears array attributes.
    #
    def wipe(*attr_ids)
      @jaba_node.wipe_attrs(attr_ids)
    end

    ##
    #
    def generate(&block)
      @jaba_node.definition.set_hook(:generate, &block)
    end

    ##
    #
    def method_missing(attr_id, *args, **keyval_args, &block)
      @jaba_node.handle_attr(attr_id, *args, __api_call_loc: ::Kernel.caller_locations(1, 1)[0], **keyval_args, &block)
    end

    ##
    # The directory this definition is in.
    #
    def __dir__
      @jaba_node.definition.source_dir
    end

    private

    ##
    #
    def initialize(jaba_node)
      @jaba_node = @obj = jaba_node
    end

  end

end
