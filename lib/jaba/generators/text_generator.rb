# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class TextGenerator < Generator
    
    ##
    #
    def generate
      @nodes.each do |n|
        attrs = n.attrs
        # TODO: warn if both content and line are used
        str = attrs.content || "#{attrs.line.join("\n")}\n"
        save_file(attrs.filename, str, attrs.eol)
      end
    end
    
    ##
    #
    def dump_jaba_output(g_root)
      @nodes.each do |n|
        g_root[:filename] = n.attrs.filename
      end
    end

  end
  
end
