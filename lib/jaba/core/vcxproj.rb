# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class Vcxproj < VSProject
    
    attr_reader :vcxproj_file
    
    ##
    #
    def init
      super
      @vcxproj_file = "#{@projroot}/#{@attrs.projname}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
    end
    
    ##
    #
    def each_config(&block)
      @node.visit_node(type_id: :config, &block)
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
      p_root[:projname] = @attrs.projname
      p_root[:host] = @host.definition_id
      p_root[:platform] = @attrs.platform_ref.definition_id
      p_root[:vcxproj] = @vcxproj_file
      p_root[:src] = @attrs.src # TODO: output actual src not the spec
      p_root[:vcglobal] = @attrs.vcglobal
      cfg_root = {}
      p_root[:configs] = cfg_root
      each_config do |c|
        cfg = {}
        attrs = c.attrs
        cfg_root[attrs.config] = cfg
        cfg[:arch] = attrs.arch_ref.definition_id
        cfg[:name] = attrs.config_name
        cfg[:defines] = attrs.defines
        cfg[:inc] = attrs.inc
        cfg[:rtti] = attrs.rtti
        cfg[:vcproperty] = attrs.vcproperty
      end
    end

    ##
    #
    def write_vcxproj
      @services.log "Generating #{@vcxproj_file}"

      w = StringWriter.new(capacity: 64 * 1024)
      @pc = StringWriter.new(capacity: 2 * 1024)
      @pg1 = StringWriter.new(capacity: 2 * 1024)
      @pg2 = StringWriter.new(capacity: 2 * 1024)
      @ps = StringWriter.new(capacity: 2 * 1024)
      @idg = StringWriter.new(capacity: 2 * 1024)

      each_config do |cfg|
        platform = cfg.attrs.arch_ref.attrs.vsname
        cfg_name = cfg.attrs.config_name
        @item_def_groups = {}

        @pc.yield_self do |w|
          w << "    <ProjectConfiguration Include=\"#{cfg_name}|#{platform}\">"
          w << "      <Configuration>#{cfg_name}</Configuration>"
          w << "      <Platform>#{platform}</Platform>"
          w << "    </ProjectConfiguration>"
        end

        @ps.yield_self do |w|
          import_group(w, label: :PropertySheets, condition: cfg_condition(cfg_name, platform)) do
            w << '    <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" ' \
                'Condition="exists(\'$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />'
          end
        end

        property_group(@pg1, label: :Configuration, condition: cfg_condition(cfg_name, platform))
        property_group(@pg2, label: :Configuration, condition: cfg_condition(cfg_name, platform))
        item_definition_group(@idg, condition: cfg_condition(cfg_name, platform))

        cfg.visit_attr(:vcproperty) do |attr, val|
          key = attr.get_option_value(:__key)
          group = attr.get_option_value(:group, fail_if_not_found: false)
          condition = attr.get_option_value(:condition, fail_if_not_found: false)

          case group
          when :pg1
            write_keyvalue(@pg1, key, val, condition: condition)
          when :pg2
            write_keyvalue(@pg2, key, val, condition: condition)
          else
            idg = @item_def_groups[group]
            if !idg
              idg = StringWriter.new(capacity: 2 * 1024)
              @item_def_groups[group] = idg
              idg << "    <#{group}>"
            end
            write_keyvalue(idg, key, val, condition: condition, depth: 3)
          end
        end

        property_group(@pg1, label: :Configuration, close: true)
        property_group(@pg2, label: :Configuration, close: true)

        @item_def_groups.each do |group, idg|
          idg << "    </#{group}>"
          @idg.write_raw(idg)
        end
        item_definition_group(@idg, close: true)
      end

      write_xml_version(w)
      
      w << "<Project DefaultTargets=\"Build\" ToolsVersion=\"#{tools_version}\" xmlns=\"#{xmlns}\">"
      
      item_group(w, label: :ProjectConfigurations) do
        w.write_raw(@pc)
      end
    
      property_group(w, label: :Globals) do
        write_keyvalue_attr(w, @node.get_attr(:vcglobal))
      end
      
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />'
      w.write_raw(@pg1)
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />'
      
      import_group(w, label: :ExtensionSettings) do
        # TODO: ExtensionSettings
      end
      
      each_config do |cfg|
        # TODO: ExtensionSettings
      end
      
      w.write_raw(@ps)
      w << '  <PropertyGroup Label="UserMacros" />'
      w.write_raw(@pg2)
      w.write_raw(@idg)
      
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
      
      import_group(w, label: :ExtensionTargets) do
        # TODO: extension targets
      end
      
      each_config do |cfg|
        # TODO: extension targets
      end
      
      w << '</Project>'
      w.chomp!
      
      @services.save_file(@vcxproj_file, w, :windows)
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
      @services.save_file(@vcxproj_filters_file, w, :windows)
    end
  
  end
  
end
