# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class TextPlugin < Plugin

    ##
    #
    def process_definition(definition)
      services.make_node
    end

    ##
    #
    def generate
      services.nodes.each do |n|
        attrs = n.attrs
        file = services.new_file(attrs.filename, eol: attrs.eol, capacity: 1024)
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
    def build_jaba_output(root)
      services.nodes.each do |n|
        root[:filename] = n.attrs.filename
      end
    end

  end
  
end
