# frozen_string_literal: true

module JABA

  ##
  #
  class Generator
    
    def build_nodes
    end
    
    ##
    #
    def save_file(filename, content, eol)
      @services.save_file(filename, content, eol)
    end
    
  end
  
  ##
  #
  class TextGenerator < Generator
    
    ##
    #
    def generate(attrs)
      str = attrs.content || "#{attrs.line.join("\n")}\n"
      save_file(attrs.filename, str, attrs.eol)
    end
    
  end
  
end
