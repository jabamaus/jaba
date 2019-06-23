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
      @proj_root = "#{@root}/#{@genroot}/#{@attrs.name}".cleanpath
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
      @platform = @attrs.platform
      @host = @attrs.host
    end
    
    ##
    #
    def tools_version
      @host.attrs.host_version_year < 2013 ? '4.0' : @host.attrs.host_version
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
      write_keyvalue_attr(w, @node.get_attr(:vcglobal))
      w << '  </PropertyGroup>'
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />'
      
      @node.children.each do |cfg|
        w << "  <PropertyGroup Label=\"Configuration\" #{cfg_condition(cfg)}>"
        write_keyvalue_attr(w, cfg.get_attr(:vcproperty), :pg1, depth: 2)
        w << '  </PropertyGroup>'
      end
      
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />'
      w << '  <ImportGroup Label="ExtensionSettings">'
      # TODO
      w << '  </ImportGroup>'
      
      @node.children.each do |cfg|
        # TODO ExtensionSettings
      end
      
      @node.children.each do |cfg|
        w << "  <ImportGroup Label=\"PropertySheets\" #{cfg_condition(cfg)}>"
        w << '    <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" Condition="exists(\'$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />'
        w << '  </ImportGroup>'
      end
    
      w << '  <PropertyGroup Label="UserMacros" />'
    
      @node.children.each do |cfg|
        w << "  <PropertyGroup Label=\"Configuration\" #{cfg_condition(cfg)}>"
        write_keyvalue_attr(w, cfg.get_attr(:vcproperty), :pg2, depth: 2)
        w << '  </PropertyGroup>'
      end
      
      @node.children.each do |cfg|
        w << "  <ItemDefinitionGroup #{cfg_condition(cfg)}>"
        w << '  </ItemDefinitionGroup>'
      end
      
      w << '  <ItemGroup>'
      # TODO: src
      w << '  </ItemGroup>'
      
      # TODO: references
      
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />'
      w << '  <ImportGroup Label="ExtensionTargets">'
      # TODO: extension targets
      w << '  </ImportGroup>'
      
      @node.children.each do |cfg|
        # TODO: extension targets
      end
      
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
    def write_keyvalue_attr(w, attr, group=nil, depth: 2)
      attr.each_value do |key_val, options, key_val_options|
        if !group || group == key_val_options[:group]
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
    
    ##
    #
    def cfg_condition(cfg)
      "Condition=\"'$(Configuration)|$(Platform)'=='#{cfg.attrs.config}|#{@platform.attrs.vsname}\""
    end
  
  end
  
end
