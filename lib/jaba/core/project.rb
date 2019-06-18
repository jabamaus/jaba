# frozen_string_literal: true

module JABA

  using JABACoreExt
  
  ##
  # Base class for instances of projects, eg a Visual Studio project/Xcode project/makefile etc.
  #
  class Project
    
    attr_reader :attrs
    attr_reader :root
    attr_reader :genroot
    
    ##
    #
    def initialize(node)
      @attrs = node.attrs
      @root = @attrs.root
      @genroot = @attrs.genroot
    end
    
    ##
    #
    def save_file(filename, content, eol)
      @services.save_file(filename, content, eol)
    end
    
  end

  ##
  #
  class Vcxproj < Project
    
    ##
    #
    def init
      @vcx_root = "#{@root}/#{@genroot}/#{attrs.projname}".cleanpath
      @vcxproj_file = "#{@vcx_root}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
    end
    
    ##
    #
    def generate
      write_vcxproj
      write_vcxproj_filters
    end
    
    ##
    #
    def write_vcxproj
      puts "Generating #{@vcxproj_file}"
      w = StringWriter.new(capacity: 64 * 1024)
      w << "\uFEFF<?xml version=\"1.0\" encoding=\"utf-8\"?>"
      w << "<Project DefaultTargets=\"Build\" ToolsVersion=\"#{tools_version}\" " \
            'xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">'
      w << '</Project>'
      w.chomp!
      save_file(@vcxproj_file, w.str, :windows)
    end
    
    ##
    #
    def write_vcxproj_filters
      w = StringWriter.new(capacity: 16 * 1024)
      w << "\uFEFF<?xml version=\"1.0\" encoding=\"utf-8\"?>"
      w << '<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">'
      w << '  <ItemGroup>'
      w << '  </ItemGroup>'
      w << '  <ItemGroup>'
      w << '  </ItemGroup>'
      w << '</Project>'
      w.chomp!
      save_file(@vcxproj_filters_file, w.str, :windows)
    end
    
    ##
    #
    def tools_version
      'TODO'
    end
    
  end
  
end
