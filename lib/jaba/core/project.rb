# frozen_string_literal: true

##
#
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
    def initialize(services, generator, node)
      @services = services
      @generator = generator
      @node = node
      @attrs = node.attrs
      @root = "#{node.source_dir}/#{@attrs.root}"
      @genroot = "#{@root}/#{@attrs.genroot}"
      @proj_root = "#{@genroot}/#{@attrs.name}".cleanpath
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
    
    attr_reader :vcxproj_file
    
    ##
    #
    def init
      @vcxproj_file = "#{@proj_root}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
      @platform = @attrs.platform
      @host = @attrs.host
      @guid = nil
      @configs = []
      
      # TODO: check for clashes if already set by user
      @attrs.vcglobal :WindowsTargetPlatformVersion, @attrs.winsdkver
      
      config_type = case @attrs.type
      when :app
        'Application'
      when :lib
        'StaticLibrary'
      when :dll
        'DynamicLibrary'
      else
        raise "'#{attrs.type}' unrecognised"
      end
      
      @attrs.configs.each do |cfg|
        @configs << @generator.make_node(handle: nil, parent: @node, attrs: [:config, :vcproperty]) do |n|
          n.attrs.config cfg
          n.attrs.vcproperty :ConfigurationType, config_type, group: :pg1
        end
      end
    end
    
    ##
    #
    def tools_version
      @host.attrs.host_version_year < 2013 ? '4.0' : @host.attrs.host_version
    end
    
    ##
    #
    def guid
      if !@guid
        if File.exist?(@vcxproj_file)
          if @services.read_file(@vcxproj_file, encoding: 'UTF-8') !~ /<ProjectGuid>(.+)<\/ProjectGuid>/
            raise "Failed to read GUID from #{@vcxproj_file}"
          end
          @guid = Regexp.last_match(1)
        else
          @guid = OS.generate_guid
        end
      end
      @guid
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
            'xmlns="http://schemas.microsoft.com/developer/msbuild/2003">'
            
      w << '  <ItemGroup Label="ProjectConfigurations">'
      @configs.each do |cfg|
        w << "    <ProjectConfiguration Include=\"#{cfg.attrs.config}|#{@platform.attrs.vsname}\">"
        w << "      <Configuration>#{cfg.attrs.config}</Configuration>"
        w << "      <Platform>#{@platform.attrs.vsname}</Platform>"
        w << '    </ProjectConfiguration>'
      end
      w << '  </ItemGroup>'
    
      w << '  <PropertyGroup Label="Globals">'
      w << "    <ProjectGuid>#{guid}</ProjectGuid>"
      write_keyvalue_attr(w, @node.get_attr(:vcglobal))
      w << '  </PropertyGroup>'
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />'
      
      @configs.each do |cfg|
        w << "  <PropertyGroup Label=\"Configuration\" #{cfg_condition(cfg)}>"
        write_keyvalue_attr(w, cfg.get_attr(:vcproperty), :pg1, depth: 2)
        w << '  </PropertyGroup>'
      end
      
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />'
      w << '  <ImportGroup Label="ExtensionSettings">'
      # TODO: ExtensionSettings
      w << '  </ImportGroup>'
      
      @configs.each do |cfg|
        # TODO: ExtensionSettings
      end
      
      @configs.each do |cfg|
        w << "  <ImportGroup Label=\"PropertySheets\" #{cfg_condition(cfg)}>"
        w << '    <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" ' \
             'Condition="exists(\'$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />'
        w << '  </ImportGroup>'
      end
    
      w << '  <PropertyGroup Label="UserMacros" />'
    
      @configs.each do |cfg|
        w << "  <PropertyGroup Label=\"Configuration\" #{cfg_condition(cfg)}>"
        write_keyvalue_attr(w, cfg.get_attr(:vcproperty), :pg2, depth: 2)
        w << '  </PropertyGroup>'
      end
      
      @configs.each do |cfg|
        w << "  <ItemDefinitionGroup #{cfg_condition(cfg)}>"
        w << '  </ItemDefinitionGroup>'
      end
      
      w << '  <ItemGroup>'
      # TODO: src
      w << '  </ItemGroup>'
      
      deps = @attrs.deps
      if !deps.empty?
        w << '  <ItemGroup>'
        deps.each do |dep|
          proj_ref = @generator.project_from_node(dep)
          w << "    <ProjectReference Include=\"#{proj_ref.vcxproj_file.relative_path_from(genroot).to_backslashes!}\">"
          w << "      <Project>#{proj_ref.guid}</Project>"
          # TODO: reference properties
          w << '    </ProjectReference>'
        end
        w << '  </ItemGroup>'
      end
    
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />'
      w << '  <ImportGroup Label="ExtensionTargets">'
      # TODO: extension targets
      w << '  </ImportGroup>'
      
      @configs.each do |cfg|
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
    def write_keyvalue_attr(w, attr, group = nil, depth: 2)
      attr.each_value do |key_val, _options, key_val_options|
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
      "Condition=\"'$(Configuration)|$(Platform)'=='#{cfg.attrs.config}|#{@platform.attrs.vsname}'\""
    end
  
  end
  
end
