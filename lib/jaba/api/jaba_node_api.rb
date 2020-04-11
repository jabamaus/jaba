# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class JabaNodeAttributeAPI < BasicObject

    ##
    #
    def initialize(node, context)
      @node = node
      @context = context
    end
    
    ##
    #
    def method_missing(attr_id, *args, **keyvalue_args)
      api_call_line = @context == :definition ? ::Kernel.caller(1, 1)[0] : nil
      @node.handle_attr(attr_id, api_call_line, *args, **keyvalue_args)
    end
   
  end
  
  ##
  #
  class JabaNodeAPI < JabaNodeAttributeAPI
    
    include APICommon

    ##
    #
    def initialize(node)
      super(node, :definition)
      @obj = node
    end

    ##
    #
    def id
      @node.id
    end

    ##
    # Clears any previously set values. Sets single attribute values to nil and clears array attributes.
    #
    def wipe(*attr_ids)
      @node.wipe_attrs(attr_ids)
    end

    ##
    #
    def generate(&block)
      @node.define_hook(:generate, allow_multiple: true, &block)
    end

  end

end
