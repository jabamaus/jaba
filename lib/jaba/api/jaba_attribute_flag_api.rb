module JABA

  ##
  #
  class JabaAttributeFlagAPI < BasicObject

    include APICommon

    ##
    # Set help for the attribute flag. Required.
    #
    def help(val = nil, &block)
      @attr_flag.set_property(:help, val, &block)
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
