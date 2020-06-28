module JABA

  ##
  #
  class JDL_AttributeFlag < BasicObject

    include JDL_Common

    ##
    # Set title of attribute flag. Required. Will appear in generated reference manual.
    #
    def title(val = nil)
      @attr_def.set_property(:title, val)
    end

    ##
    # Add a help note for the attribute flag. Multiple can be added. Will appear in generated reference manual.
    #
    def note(val)
      @attr_flag.set_property(:notes, val)
    end

    ##
    # Add usage example. Will appear in generated reference manual.
    #
    def example(val)
      @attr_flag.set_property(:examples, val)
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
