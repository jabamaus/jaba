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
  class VSProject < Project
  
    ##
    #
    def init
      @guid = nil
      @host = @attrs.host
      @platform = @attrs.platform
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
    def write_xml_version(w)
      w << "\uFEFF<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    end
    
    ##
    #
    def xmlns
      'http://schemas.microsoft.com/developer/msbuild/2003'
    end
    
    ##
    #
    def xml_group(w, tag, label: nil, condition: nil, depth: 1)
      w.write_raw "#{'  ' * depth}<#{tag}"
      w.write_raw " Label=\"#{label}\"" if label
      w.write_raw " Condition=\"#{condition}\"" if condition
      w << '>'
      yield
      w << "#{'  ' * depth}</#{tag}>"
    end

    ##
    #
    def item_group(w, **options, &block)
      xml_group(w, 'ItemGroup', **options, &block)
    end
    
    ##
    #
    def property_group(w, **options, &block)
      xml_group(w, 'PropertyGroup', **options, &block)
    end
    
    ##
    #
    def import_group(w, **options, &block)
      xml_group(w, 'ImportGroup', **options, &block)
    end
    
    ##
    #
    def item_definition_group(w, **options, &block)
      xml_group(w, 'ItemDefinitionGroup', **options, &block)
    end
    
    ##
    #
    def write_keyvalue_attr(w, attr, group: nil, depth: 2)
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
      "'$(Configuration)|$(Platform)'=='#{cfg.attrs.config}|#{@platform.attrs.vsname}'"
    end
    
  end
  
  ##
  #
  class Vcxproj < VSProject
    
    attr_reader :vcxproj_file
    attr_reader :configs
    
    ##
    #
    def init
      super
      @vcxproj_file = "#{@proj_root}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
      @configs = @node.children
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
      
      write_xml_version(w)
      
      w << "<Project DefaultTargets=\"Build\" ToolsVersion=\"#{tools_version}\" xmlns=\"#{xmlns}\">"
      
      item_group(w, label: 'ProjectConfigurations') do
        @configs.each do |cfg|
          w << "    <ProjectConfiguration Include=\"#{cfg.attrs.config}|#{@platform.attrs.vsname}\">"
          w << "      <Configuration>#{cfg.attrs.config}</Configuration>"
          w << "      <Platform>#{@platform.attrs.vsname}</Platform>"
          w << '    </ProjectConfiguration>'
        end
      end
    
      property_group(w, label: 'Globals') do
        write_keyvalue_attr(w, @node.get_attr(:vcglobal))
      end
      
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />'
      
      @configs.each do |cfg|
        property_group(w, label: 'Configuration', condition: cfg_condition(cfg)) do
          write_keyvalue_attr(w, cfg.get_attr(:vcproperty), group: :pg1)
        end
      end
      
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />'
      
      import_group(w, label: 'ExtensionSettings') do
        # TODO: ExtensionSettings
      end
      
      @configs.each do |cfg|
        # TODO: ExtensionSettings
      end
      
      @configs.each do |cfg|
        import_group(w, label: 'PropertySheets', condition: cfg_condition(cfg)) do
          w << '    <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" ' \
               'Condition="exists(\'$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />'
        end
      end
    
      w << '  <PropertyGroup Label="UserMacros" />'
    
      @configs.each do |cfg|
        property_group(w, label: 'Configuration', condition: cfg_condition(cfg)) do
          write_keyvalue_attr(w, cfg.get_attr(:vcproperty), group: :pg2)
        end
      end
      
      @configs.each do |cfg|
        item_definition_group(w, condition: cfg_condition(cfg)) do
          
        end
      end
      
      item_group(w) do
        # TODO: src
      end
      
      deps = @attrs.deps
      if !deps.empty?
        item_group(w) do
          deps.each do |dep|
            proj_ref = @generator.project_from_node(dep)
            w << "    <ProjectReference Include=\"#{proj_ref.vcxproj_file.relative_path_from(genroot).to_backslashes!}\">"
            w << "      <Project>#{proj_ref.guid}</Project>"
            # TODO: reference properties
            w << '    </ProjectReference>'
          end
        end
      end
    
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />'
      
      import_group(w, label: 'ExtensionTargets') do
        # TODO: extension targets
      end
      
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
      
      write_xml_version(w)
      w << "<Project ToolsVersion=\"4.0\" xmlns=\"#{xmlns}\">"
      item_group(w) do
      end
      item_group(w) do
      end
      w << '</Project>'
      w.chomp!
      save_file(@vcxproj_filters_file, w.str, :windows)
    end
  
  end
  
end
