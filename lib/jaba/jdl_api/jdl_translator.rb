module JABA

  ##
  #
  class JDL_Translator < BasicObject

    include JDL_Common

    ##
    #
    def method_missing(attr_id, *args, **keyval_args, &block)
      @translator.handle_attr(attr_id, *args, __api_call_loc: ::Kernel.caller_locations(1, 1)[0], **keyval_args, &block)
    end

    private

    ##
    #
    def initialize(translator)
      @translator = @obj = translator
    end

  end

end
