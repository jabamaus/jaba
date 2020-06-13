# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class Translator < JDL_Object

    ##
    #
    def initialize(services, definition, open_defs)
      super(services, definition, JDL_Translator.new(self))

      @open_defs = open_defs
    end

    ##
    #
    def execute(node:, args:)
      @node = node
      eval_jdl(*args, &@definition.block)
      @open_defs&.each do |d|
        eval_jdl(*args, &d.block)
      end
    end

    ##
    #
    def handle_attr(...)
      @node.handle_attr(...)
    end

  end

end
