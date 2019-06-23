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
        str = attrs.content || "#{attrs.line.join("\n")}\n"
        save_file(attrs.filename, str, attrs.eol)
      end
    end
    
  end
  
end
