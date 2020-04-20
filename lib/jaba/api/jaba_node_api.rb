module JABA

  ##
  #
  class JabaNodeAPI < BasicObject

    include APICommon

    ##
    #
    def _ID
      @jaba_node.definition_id
    end

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
    # Block runs in the context of an internal JabaNode object not the JabaNodeAPI.
    #
    def generate(&block)
      @jaba_node.define_hook(:generate, allow_multiple: true, &block)
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
