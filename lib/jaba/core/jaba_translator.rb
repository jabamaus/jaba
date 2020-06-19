# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class Translator < JDL_Object

    ##
    #
    def initialize(definition)
      super(definition, JDL_Translator.new(self))
    end

    ##
    #
    def execute(node:, args:)
      @node = node
      eval_jdl(*args, &@definition.block)
      @definition.open_defs.each do |d|
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
