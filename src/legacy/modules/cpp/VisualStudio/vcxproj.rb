module JABA

  class Vcxproj < VSProj
    attr_reader :projname
    attr_reader :vcxproj_file
    attr_reader :has_resources
    
    def initialize(plugin, node)
      super
      @projname = @attrs.projname
      @vcxproj_file = "#{@projdir}/#{@projname}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
      @file_type_hash = services.globals.vcfiletype
      @has_resources = false
      @masm_required = false
      @per_file_props = {}
      @extension_settings = []
      @extension_targets = []
    end

    def post_create
      process_src(:src, :src_ext, :src_exclude)

      @has_resources = @src.any?{|sf| sf.extname == '.rc'}

      # Call translator for this platform to initialse project level Visual Studio-specific attributes
      # (vcglobals), based on cross platform definition.
      #
      platform = @node.attrs.platform
      t = services.get_translator("vcxproj_#{platform}".to_sym)
      t.execute(node: @node, args: [self])
      
      # Call translator to initialise configuration level Visual Studio-specific attributes (vcprop)
      # based on cross platform definition.
      #
      each_config do |cfg|
        cfg_name = cfg.attrs.configname
        platform_name = cfg.attrs.arch.attrs.vsname
        t = services.get_translator("vcxproj_config_#{platform}".to_sym)
        t.execute(node: cfg, args: [self, cfg.attrs.type])

        pchsrc_attr = cfg.get_attr(:pchsrc)
        pchsrc = pchsrc_attr.value
        if pchsrc
          # Check pchsrc is a valid src file
          #
          get_matching_src_objs(pchsrc, @src, errobj: pchsrc_attr)
          cfg.attrs.vcfprop "#{pchsrc}|PrecompiledHeader", :Create
        end

        # Build events. Standard across platforms.
        #
        shell_cmds = {}
        cfg.visit_attr(:shell) do |attr, value|
          type = attr.get_option_value(:when)
          group = case type
          when :PreBuild, :PreLink, :PostBuild
            "#{type}Event"
          end
          shell_cmds.push_value(group, value)
        end

        shell_cmds.each do |group, cmds|
          cfg.attrs.vcprop "#{group}|Command", cmds.join("\n")
        end

        cfg.visit_attr(:rule) do |attr, rule_node|
          attrs = rule_node.attrs
          output = attrs.output
          implicit_input = attrs.implicit_input&.relative_path_from(@projdir, backslashes: true)
          cmd_attr = rule_node.get_attr(:cmd)
          cmd = cmd_attr.value
          cmd_abs = cmd_attr.has_flag_option?(:absolute)
          msg = attrs.msg

          # TODO: input and output should be automatically added to src so user
          # doesn't have to specify twice
          attrs.input.flat_map{|spec| get_matching_src_objs(spec, @src, errobj: attr)}.each do |sf|
            sf.file_type = :CustomBuild

            # TODO: check output a valid src file
            input = sf.projdir_rel
            d_output = demacroise(output, input, implicit_input, nil)
            
            d_cmd = nil
            if cmd_abs
              d_cmd = demacroise(
                cmd,
                sf.absolute_path,
                implicit_input ? "$(ProjectDir)#{implicit_input}" : nil,
                d_output
              )
            end

            d_output = d_output.relative_path_from(@projdir, backslashes: true)

            if !cmd_abs
              d_cmd = demacroise(
                cmd,
                "$(ProjectDir)#{input}",
                implicit_input ? "$(ProjectDir)#{implicit_input}" : nil,
                "$(ProjectDir)#{d_output}"
              )
            end
            d_cmd = d_cmd.to_escaped_xml
            # Characters like < > | & are escaped to prevent unwanted behaviour when the msg is echoed
            d_msg = demacroise(msg, input, implicit_input, d_output).to_escaped_DOS.to_escaped_xml

            @per_file_props.push_value(sf, [:FileType, cfg_name, platform_name, :Document])
            @per_file_props.push_value(sf, [:Command, cfg_name, platform_name, d_cmd])
            @per_file_props.push_value(sf, [:Outputs, cfg_name, platform_name, d_output])
            additional_inputs = [:AdditionalInputs, cfg_name, platform_name]
            if implicit_input
              additional_inputs << implicit_input
              @per_file_props.push_value(sf, additional_inputs)
            end
            @per_file_props.push_value(sf, [:Message, cfg_name, platform_name, d_msg])
          end
        end
      end
    end
    
    def demacroise(str, input, implicit_input, output)
      str = str.dup
      matches = str.scan(/(\$\((.+?)(\.(.+?))?\))/)
      matches.each do |match|
        full_var = match[0]
        var = match[1]
        method = match[3]
        repl = case var
        when /^input/
          input
        when /^implicit_input/
          JABA.error("No  implicit_input supplied") if implicit_input.nil?
          implicit_input
        when /^output/
          output
        end
        if repl.nil?
          JABA.error("Invalid macro '#{full_var}' in #{str}") # TODO: err_obj
        end
        if !method.nil?
          repl = repl.instance_eval(method)
        end
        # Important to use block form of gsub to disable backreferencing
        #
        str.gsub!(full_var){ repl }
      end
      str
    end

    # Overridden from Project. Yields eg :ClCompile given '.cpp'.
    #
    def file_type_from_extension(ext)
      ft = @file_type_hash[ext]
      return ft if ft
      :None
    end

    def each_config(&block)
      @node.visit_node(type_id: :cpp_config, &block)
    end

    def generate
      write_vcxproj
      write_vcxproj_filters
    end
    
    def build_output(p_root)
      p_root[:projdir] = @projdir
      p_root[:projname] = @projname
      p_root[:host] = @host.defn_id
      p_root[:platform] = @attrs.platform.defn_id
      p_root[:vcxproj] = @vcxproj_file
      p_root[:src] = @src.map{|f| f.absolute_path}
      p_root[:vcglobal] = @attrs.vcglobal
      cfg_root = {}
      p_root[:configs] = cfg_root
      each_config do |c|
        attrs = c.attrs
        arch_root = cfg_root[attrs.arch.defn_id]
        if !arch_root
          arch_root = {}
          cfg_root[attrs.arch.defn_id] = arch_root
        end
        cfg = {}
        arch_root[attrs.config] = cfg
        cfg[:define] = attrs.define
        cfg[:inc] = attrs.inc
        cfg[:rtti] = attrs.rtti
        cfg[:syslibs] = attrs.syslibs
        cfg[:vcprop] = attrs.vcprop
      end
    end

    # See https://docs.microsoft.com/en-us/cpp/build/reference/vcxproj-file-structure?view=vs-2019
    #
    def write_vcxproj
      services.log "Generating #{@vcxproj_file}", section: true
      
      file = services.new_file(@vcxproj_file, eol: :windows, encoding: 'UTF-8', capacity: 128 * 1024)
      w = file.writer
      c = 32 * 1024
      @pc = file.work_area(capacity: c)
      @pg1 = file.work_area(capacity: c)
      @pg2 = file.work_area(capacity: c)
      @ps = file.work_area(capacity: c)
      @idg = file.work_area(capacity: c)

      each_config do |cfg|
        platform = cfg.attrs.arch.attrs.vsname
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

        cfg.visit_attr(:vcprop) do |attr, val|
          group, key = attr.get_option_value(:__key).split('|')
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

        cfg.visit_attr(:vcfprop) do |attr, val|
          file_with_prop, prop = attr.get_option_value(:__key).split('|')
          sfs = get_matching_src_objs(file_with_prop, @src, errobj: attr)
          sfs.each do |sf|
            @per_file_props.push_value(sf, [prop, cfg_name, platform, val])
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
      
      src_area = file.work_area(capacity: c)
      @src.each do |sf|
        ft = sf.file_type
        file_props = @per_file_props[sf]
        src_area.write_raw("    <#{ft} Include=\"#{sf.projdir_rel}\"")
        if file_props
          src_area << ">"
          file_props.each_slice(4) do |a|
            src_area << "      <#{a[0]} Condition=\"#{cfg_condition(a[1], a[2])}\">#{a[3]}</#{a[0]}>"
          end
          src_area << "    </#{ft}>"
        else
          src_area << " />"
        end

        es = @attrs.vc_extension_settings[sf.extname]
        if es
          @extension_settings << es.relative_path_from(projdir, backslashes: true)
        end
        et = @attrs.vc_extension_targets[sf.extname]
        if et
          @extension_targets << et.relative_path_from(projdir, backslashes: true)
        end
        if ft == :MASM
          @masm_required = true
        end
      end
      
      import_group(w, label: :ExtensionSettings) do
        @extension_settings.each do |es|
          w << "    <Import Project=\"#{es}\" />"
        end
        if @masm_required
          w << '  <Import Project="$(VCTargetsPath)\BuildCustomizations\masm.props" />'
        end
      end
      
      each_config do |cfg|
        # TODO: ExtensionSettings
      end
      
      w.write_raw(@ps)
      w << '  <PropertyGroup Label="UserMacros" />'
      w.write_raw(@pg2)
      w.write_raw(@idg)
      
      item_group(w) do
        w.write_raw(src_area)
      end
      
      if !@attrs.deps.empty?
        item_group(w) do
          @node.visit_attr(:deps) do |attr, value|
            soft = attr.has_flag_option?(:soft)
            if !soft
              dep_node = value
              proj_ref = @plugin.project_from_node(dep_node)
              w << "    <ProjectReference Include=\"#{proj_ref.vcxproj_file.relative_path_from(projdir, backslashes: true)}\">"
              w << "      <Project>#{proj_ref.guid}</Project>"
              # TODO: reference properties
              w << '    </ProjectReference>'
            end
          end
        end
      end
    
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />'
      
      import_group(w, label: :ExtensionTargets) do
        @extension_targets.each do |et|
          w << "    <Import Project=\"#{et}\" />"
        end
        if @masm_required
          w << '    <Import Project="$(VCTargetsPath)\BuildCustomizations\masm.targets" />'
        end
      end
      
      each_config do |cfg|
        # TODO: extension targets
      end
      
      w << '</Project>'
      w.chomp!
      
      file.write
    end
    
    # See https://docs.microsoft.com/en-us/cpp/build/reference/vcxproj-filters-files?view=vs-2019
    #
    def write_vcxproj_filters
      file = services.new_file(@vcxproj_filters_file, eol: :windows, encoding: 'UTF-8', capacity: 16 * 1024)
      w = file.writer

      write_xml_version(w)
      w << "<Project ToolsVersion=\"4.0\" xmlns=\"#{xmlns}\">"
      
      item_group(w) do
        filters = {}
        @src.each do |sf|
          vp = sf.vpath
          while vp && vp != '.' && !filters.key?(vp)
            filters[vp] = nil
            vp = vp.parent_path
          end
        end
        
        filters.each_key do |f|
          w << "    <Filter Include=\"#{f}\">"
          # According to Visual Studio docs UniqueIdentifier allows automation interfaces to find the filter.
          # Seed the GUID from project file basename rather than absolute path as that could change
          #
          w << "      <UniqueIdentifier>#{Kernel.generate_uuid(namespace: @vcxproj_file.basename, name: f, braces: true)}</UniqueIdentifier>"
          w << "    </Filter>"
        end
      end

      item_group(w) do
        @src.each do |sf|
          if sf.vpath
            w << "    <#{sf.file_type} Include=\"#{sf.projdir_rel}\">"
            w << "      <Filter>#{sf.vpath}</Filter>"
            w << "    </#{sf.file_type}>"
          else
            w << "    <#{sf.file_type} Include=\"#{sf.projdir_rel}\" />"
          end
        end
      end
      w << '</Project>'
      w.chomp!
      file.write
    end
  end  
end
