# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class Vcxproj < VSProj
    
    attr_reader :vcxproj_file
    
    ##
    #
    def init
      super
      @projname = @attrs.projname
      @vcxproj_file = "#{@projroot}/#{@projname}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
      @file_type_hash = services.globals_node.get_attr(:vcfiletype).value

      # Call translator for this platform to initialse project level Visual Studio-specific attributes
      # (vcglobals), based on cross platform definition.
      #
      platform = @node.attrs.platform
      t = services.get_translator("vcxproj_#{platform}".to_sym)
      t.execute(node: @node, args: [self])
      
      # Call translator to initialise configuration level Visual Studio-specific attributes (vcproperty)
      # based on cross platform definition.
      #
      each_config do |cfg|
        t = services.get_translator("vcxproj_config_#{platform}".to_sym)
        t.execute(node: cfg, args: [self, cfg.attrs.type], &t.definition.block)

        # Build events. Standard across platforms.
        #
        shell_cmds = {}
        cfg.visit_attr(:shell) do |a, value|
          type = a.get_option_value(:when)
          group = case type
          when :PreBuild, :PreLink, :PostBuild
            "#{type}Event"
          end
          shell_cmds.push_value(group, value)
        end

        shell_cmds.each do |group, cmds|
          cfg.attrs.vcproperty "#{group}|Command", cmds.join("\n")
        end
      end
    end
    
    ##
    # Overridden from Project. Yields eg :ClCompile given '.cpp'.
    #
    def file_type_from_extension(ext)
      ft = @file_type_hash[ext]
      return ft if ft
      :None
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
    def build_jaba_output(p_root, out_dir)
      p_root[:projroot] = @projroot.relative_path_from(out_dir)
      p_root[:projname] = @projname
      p_root[:host] = @host.defn_id
      p_root[:platform] = @attrs.platform_ref.defn_id
      p_root[:vcxproj] = @vcxproj_file.relative_path_from(out_dir)
      p_root[:src] = @src.map{|f| f.absolute_path.relative_path_from(out_dir)}
      p_root[:vcglobal] = @attrs.vcglobal
      cfg_root = {}
      p_root[:configs] = cfg_root
      each_config do |c|
        cfg = {}
        attrs = c.attrs
        cfg_root[attrs.config] = cfg
        # TODO: organise by group. Build at the same time is generating
        cfg[:arch] = attrs.arch_ref.defn_id
        cfg[:name] = attrs.configname
        cfg[:defines] = attrs.defines
        cfg[:inc] = attrs.inc
        cfg[:rtti] = attrs.rtti
        cfg[:vcproperty] = attrs.vcproperty
      end
    end

    ##
    # See https://docs.microsoft.com/en-us/cpp/build/reference/vcxproj-file-structure?view=vs-2019
    #
    def write_vcxproj
      services.log "Generating #{@vcxproj_file}", section: true
      
      file = services.file_manager.new_file(@vcxproj_file, eol: :windows, encoding: 'UTF-8', capacity: 128 * 1024)
      
      w = file.writer
      c = 32 * 1024
      @pc = file.work_area(capacity: c)
      @pg1 = file.work_area(capacity: c)
      @pg2 = file.work_area(capacity: c)
      @ps = file.work_area(capacity: c)
      @idg = file.work_area(capacity: c)

      each_config do |cfg|
        platform = cfg.attrs.arch_ref.attrs.vsname
        cfg_name = cfg.attrs.configname
        @item_def_groups = {}

        @pc.yield_self do |w|
          w << "    <ProjectConfiguration Include=\"#{cfg_name}|#{platform}\">"
          w << "      <Configuration>#{cfg_name}</Configuration>"
          w << "      <Platform>#{platform}</Platform>"
          w << "    </ProjectConfiguration>"
        end

        @ps.yield_self do |w|
          import_group(w, label: :PropertySheets, label_at_end: false, condition: cfg_condition(cfg_name, platform)) do
            w << '    <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" ' \
                'Condition="exists(\'$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />'
          end
        end

        property_group(@pg1, label: :Configuration, label_at_end: true, condition: cfg_condition(cfg_name, platform))
        property_group(@pg2, condition: cfg_condition(cfg_name, platform))
        item_definition_group(@idg, condition: cfg_condition(cfg_name, platform))

        cfg.visit_attr(:vcproperty) do |attr, val|
          location = attr.get_option_value(:__key)
          group, key = location.split('|')
          condition = attr.get_option_value(:condition, fail_if_not_found: false)

          case group
          when 'PG1'
            write_keyvalue(@pg1, key, val, condition: condition)
          when 'PG2'
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

        property_group(@pg1, close: true)
        property_group(@pg2, close: true)

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
        @src.each do |sf|
          w << "    <#{sf.file_type} Include=\"#{sf.projroot_rel}\" />"
        end
      end
      
      deps = @attrs.deps
      if !deps.empty?
        item_group(w) do
          deps.each do |dep|
            proj_ref = @generator.project_from_node(dep)
            w << "    <ProjectReference Include=\"#{proj_ref.vcxproj_file.relative_path_from(projroot, backslashes: true)}\">"
            w << "      <Project>#{proj_ref.attrs.guid}</Project>"
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
      
      file.write
    end
    
    ##
    # See https://docs.microsoft.com/en-us/cpp/build/reference/vcxproj-filters-files?view=vs-2019
    #
    def write_vcxproj_filters
      file = services.file_manager.new_file(@vcxproj_filters_file, eol: :windows, encoding: 'UTF-8', capacity: 16 * 1024)
      w = file.writer

      write_xml_version(w)
      w << "<Project ToolsVersion=\"4.0\" xmlns=\"#{xmlns}\">"
      
      item_group(w) do
        filters = {}
        @src.each do |sf|
          vp = sf.vpath
          while vp && vp != '.' && !filters.key?(vp)
            filters[vp] = nil
            vp = vp.dirname
          end
        end
        
        # Filters can have an optional guid in the form:
        #   <UniqueIdentifier>{D5562E0F-416B-56C0-0AED-F91F76C052F1}</UniqueIdentifier>
        # According to Visual Studio docs it allows automation interfaces to find the filter.
        # I'm not sure if its really required.
        # Visual Studio creates the guid by hashing the filter so the same guid will appear in
        # multiple files if the filters are the same.
        #
        # TODO: investigate whether this is really needed
        # 
        filters.each_key do |f|
          w << "    <Filter Include=\"#{f}\" />"
        end
      end

      item_group(w) do
        @src.each do |sf|
          if sf.vpath
            w << "    <#{sf.file_type} Include=\"#{sf.projroot_rel}\">"
            w << "      <Filter>#{sf.vpath}</Filter>"
            w << "    </#{sf.file_type}>"
          else
            w << "    <#{sf.file_type} Include=\"#{sf.projroot_rel}\" />"
          end
        end
      end
      w << '</Project>'
      w.chomp!
      file.write
    end
  
  end
  
end
