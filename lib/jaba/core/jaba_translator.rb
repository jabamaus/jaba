# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class Translator < JabaObject

    ##
    #
    def initialize(services, defn_id, src_loc, block)
      super(services, defn_id, src_loc, JDL_Translator.new(self))
      @block = block
    end

    ##
    #
    def execute(node:, args:)
      @node = node
      eval_jdl(*args, &@block)

      tdef = services.get_translator_definition(defn_id)
      tdef.open_defs.each do |d|
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
