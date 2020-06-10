module JABA

  ##
  #
  class JDL_AttributeFlag < BasicObject

    include JDL_Common

    ##
    # Set help for the attribute flag. Required.
    #
    def help(val)
      @attr_flag.set_property(:help, val)
    end

    ##
    #
    def compatibility(&block)
      @attr_flag.set_hook(:compatibility, &block)
    end

    private

    ##
    #
    def initialize(attr_flag)
      @attr_flag = @obj = attr_flag
    end

  end

end
