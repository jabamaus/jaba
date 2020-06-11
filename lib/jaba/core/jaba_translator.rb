# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class Translator < JDL_Object

    def initialize(services, definition)
      super(services, definition, JDL_Translator.new(self))
    end

    ##
    #
    def set_node(node)
      @node = node
    end

    ##
    #
    def handle_attr(...)
      @node.handle_attr(...)
    end

  end

end
