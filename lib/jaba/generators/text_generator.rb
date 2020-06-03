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
        file = @services.file_manager.new_file(attrs.filename, eol: attrs.eol, capacity: 1024)
        w = file.writer
        c = attrs.content
        w.write_raw(c) if c
        lines = attrs.line
        if !lines.empty?
          w << "#{lines.join("\n")}"
        end
        file.save
      end
    end
    
    ##
    #
    def build_jaba_output(g_root)
      @nodes.each do |n|
        g_root[:filename] = n.attrs.filename
      end
    end

  end
  
end
