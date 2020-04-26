# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class Vcxproj < VSProject
    
    attr_reader :vcxproj_file
    attr_reader :configs
    
    ##
    #
    def init
      super
      @vcxproj_file = "#{@projroot}/#{@attrs.projname}.vcxproj"
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
    def dump_jaba_output(p_root)
      p_root[:projroot] = @projroot
      p_root[:platform] = @platform.definition_id
      p_root[:host] = @host.definition_id
      p_root[:guid] = @guid
      p_root[:vcxproj] = @vcxproj_file
      cfg_root = {}
      p_root[:configs] = cfg_root
      @configs.each do |c|
        cfg = {}
        cfg_root[c.attrs.config] = cfg
        cfg[:name] = c.attrs.config_name
        cfg[:rtti] = c.attrs.rtti
      end
    end

    ##
    #
    def write_vcxproj
      @services.log "Generating #{@vcxproj_file}"
      w = StringWriter.new(capacity: 64 * 1024)
      
      write_xml_version(w)
      
      w << "<Project DefaultTargets=\"Build\" ToolsVersion=\"#{tools_version}\" xmlns=\"#{xmlns}\">"
      
      item_group(w, label: 'ProjectConfigurations') do
        @configs.each do |cfg|
          w << "    <ProjectConfiguration Include=\"#{cfg.attrs.config_name}|#{@platform.attrs.vsname}\">"
          w << "      <Configuration>#{cfg.attrs.config_name}</Configuration>"
          w << "      <Platform>#{@platform.attrs.vsname}</Platform>"
          w << '    </ProjectConfiguration>'
        end
      end
    
      property_group(w, label: 'Globals') do
        write_keyvalue_attr(w, @node.get_attr(:vcglobal)) # Attribute object itself required here
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
            w << "    <ProjectReference Include=\"#{proj_ref.vcxproj_file.relative_path_from(projroot).to_backslashes!}\">"
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
      
      @services.save_file(@vcxproj_file, w.str, :windows)
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
      @services.save_file(@vcxproj_filters_file, w.str, :windows)
    end
  
  end
  
end
