module JABA

  ##
  #
  class JabaNodeAPI < BasicObject

    include APICommon

    ##
    # Clears any previously set values. Sets single attribute values to nil and clears array attributes.
    #
    def wipe(*attr_ids)
      @jaba_node.wipe_attrs(attr_ids)
    end

    ##
    #
    def generate(&block)
      @jaba_node.set_hook(:generate, &block)
    end

    ##
    #
    def method_missing(attr_id, *args, **keyvalue_args)
      @jaba_node.handle_attr(attr_id, ::Kernel.caller(1, 1)[0], *args, **keyvalue_args)
    end

    private

    ##
    #
    def initialize(jaba_node)
      @jaba_node = @obj = jaba_node
    end

  end

end
