module JABA
  class Translator < JabaObject
    include TranslatorAPI
    
    def initialize(services, defn_id, src_loc, block, open_defs)
      super(services, defn_id, src_loc, JDL_Translator.new(self))
      @block = block
      @open_defs = open_defs
    end

    def execute(node:, args:)
      @node = node
      eval_jdl(*args, &@block)

      @open_defs&.each do |d|
        eval_jdl(*args, &d.block)
      end
    end

    def handle_attr_from_jdl(...)
      @node.handle_attr_from_jdl(...)
    end
  end
end
