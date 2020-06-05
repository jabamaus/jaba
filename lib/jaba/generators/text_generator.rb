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
        file.write
      end
    end
    
    ##
    #
    def build_jaba_output(g_root, out_dir)
      @nodes.each do |n|
        g_root[:filename] = n.attrs.filename.relative_path_from(out_dir)
      end
    end

  end
  
end
