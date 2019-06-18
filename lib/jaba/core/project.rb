# frozen_string_literal: true

module JABA

  using JABACoreExt
  
  ##
  # Base class for instances of projects, eg a Visual Studio project/Xcode project/makefile etc.
  #
  class Project
    
    attr_reader :node
    attr_reader :attrs
    attr_reader :root
    attr_reader :genroot
    
    ##
    #
    def initialize(node)
      @node = node
      @attrs = node.attrs
      @root = @attrs.root
      @genroot = @attrs.genroot
      @proj_root = "#{@root}/#{@genroot}/#{attrs.name}".cleanpath
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
      @vcxproj_file = "#{@proj_root}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
    end
    
    ##
    #
    def tools_version
      'TODO'
    end
    
    ##
    #
    def generate
      write_vcxproj
      write_vcxproj_filters
    end
    
    private
    
    ##
    #
    def write_vcxproj
      puts "Generating #{@vcxproj_file}"
      w = StringWriter.new(capacity: 64 * 1024)
      w << "\uFEFF<?xml version=\"1.0\" encoding=\"utf-8\"?>"
      w << "<Project DefaultTargets=\"Build\" ToolsVersion=\"#{tools_version}\" " \
            'xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">'
      w << '  <PropertyGroup Label="Globals">'
      write_keyvalue_attr(w, :vcglobal)
      w << '  </PropertyGroup>'
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />'
      
      # TODO: configs
      
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />'
      w << '  <ImportGroup Label="ExtensionSettings">'
      w << '  </ImportGroup>'
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
    def write_keyvalue_attr(w, attr_id, depth: 2)
      @node.get_attr(attr_id).each_value do |key_val, options, key_val_options|
        key = key_val.key
        val = key_val.value
        condition = key_val_options[:condition]
        w << if condition
          "#{'  ' * depth}<#{key} Condition=\"#{condition}\">#{val}</#{key}>"
        else
          "#{'  ' * depth}<#{key}>#{val}</#{key}>"
        end
      end
    end
  
  end
  
end
