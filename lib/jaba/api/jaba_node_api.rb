module JABA

  ##
  #
  class JabaNodeAPI < BasicObject

    include APICommon

    ##
    #
    def _FILE
      @jaba_node.source_file
    end
    
    ##
    #
    def _DIR
      @jaba_node.source_dir
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
      @jaba_node.set_hook(:generate, &block)
    end

  private
  
    ##
    #
    def method_missing(attr_id, *args, **keyvalue_args)
      api_call_line = ::Kernel.caller(1, 1)[0]
      @jaba_node.handle_attr(attr_id, api_call_line, *args, **keyvalue_args)
    end

    ##
    #
    def initialize(jaba_node)
      @jaba_node = @obj = jaba_node
    end

  end

end
