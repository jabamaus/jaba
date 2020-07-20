module JABA

  ##
  #
  class JDL_Node < BasicObject

    include JDL_Common

    ##
    # Access the attributes of the globals node.
    #
    def globals
      @jaba_node.services.globals_singleton.api
    end

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

    private

    ##
    #
    def initialize(jaba_node)
      @jaba_node = @obj = jaba_node
    end

  end

end
