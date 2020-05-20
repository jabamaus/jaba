# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class TextGenerator < Generator
    
    ##
    #
    def generate
      @nodes.each do |n|
        attrs = n.attrs
        s = String.new(capacity: 1024)
        c = attrs.content
        s << c if c
        lines = attrs.line
        if !lines.empty?
          s << "#{lines.join("\n")}\n"
        end
        @services.save_file(attrs.filename, s, attrs.eol)
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
