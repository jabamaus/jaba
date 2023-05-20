module JABA
  class Vcxproj
    include VSUtilities

    def initialize(target_node)
      @node = target_node
    end

    def projdir = @projdir

    def process
      @projname = @node[:projname]
      @projdir = @node[:projdir]
      @vcxproj_file = "#{@projdir}/#{@projname}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
      @per_file_props = {}
      @extension_settings = []
      @extension_targets = []

      t = @node.node_def.jdl_builder.lookup_translator(:vcxproj_windows)
      @node.eval_jdl(self, &t)

      t = @node.node_def.jdl_builder.lookup_translator(:vcxproj_config_windows)

      each_config do |cfg|
        cfg.eval_jdl(self, cfg[:type], &t)
      end
    end

    def generate
      write_vcxproj
      write_vcxproj_filters
    end

    def each_config(&block)
      @node.children.each(&block)
    end

    XMLVERSION = "\uFEFF<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    XMLNS = "http://schemas.microsoft.com/developer/msbuild/2003"

    # See https://docs.microsoft.com/en-us/cpp/build/reference/vcxproj-file-structure?view=vs-2019
    def write_vcxproj
      JABA.log "Generating #{@vcxproj_file}", section: true
      file = JABA.context.file_manager.new_file(@vcxproj_file, eol: :windows, encoding: "UTF-8")
      w = file.writer
      @pc = file.work_area
      @pg1 = file.work_area
      @pg2 = file.work_area
      @ps = file.work_area
      @idg = file.work_area

      each_config do |cfg|
        platform = "x64" # TODO: cfg.attrs.arch.attrs.vsname
        cfg_name = cfg[:configname]
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
          group, key = attr.option_value(:__key).split("|")
          condition = attr.option_value(:condition, fail_if_not_found: false)

          case group
          when "PG1"
            write_keyvalue(@pg1, key, val, condition: condition)
          when "PG2"
            write_keyvalue(@pg2, key, val, condition: condition)
          else
            idg = @item_def_groups[group]
            if !idg
              idg = StringWriter.new
              @item_def_groups[group] = idg
              idg << "    <#{group}>"
            end
            write_keyvalue(idg, key, val, condition: condition, depth: 3)
          end
        end
=begin
        cfg.visit_attr(:vcfprop) do |attr, val|
          file_with_prop, prop = attr.option_value(:__key).split('|')
          sfs = get_matching_src_objs(file_with_prop, @src, errobj: attr)
          sfs.each do |sf|
            @per_file_props.push_value(sf, [prop, cfg_name, platform, val])
          end
        end
=end
        property_group(@pg1, close: true)
        property_group(@pg2, close: true)

        @item_def_groups.each do |group, idg|
          idg << "    </#{group}>"
          @idg.write_raw(idg)
        end
        item_definition_group(@idg, close: true)
      end

      w << XMLVERSION
      w << "<Project DefaultTargets=\"Build\" ToolsVersion=\"#{tools_version}\" xmlns=\"#{XMLNS}\">"

      item_group(w, label: :ProjectConfigurations) do
        w.write_raw(@pc)
      end

      property_group(w, label: :Globals) do
        write_keyvalue_attr(w, @node.get_attr(:vcglobal))
      end

      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />'
      w.write_raw(@pg1)
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />'
=begin
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
=end
      import_group(w, label: :ExtensionSettings) do
        @extension_settings.each do |es|
          w << "    <Import Project=\"#{es}\" />"
        end
=begin
        if @masm_required
          w << '  <Import Project="$(VCTargetsPath)\BuildCustomizations\masm.props" />'
        end
=end
      end

      each_config do |cfg|
        # TODO: ExtensionSettings
      end

      w.write_raw(@ps)
      w << '  <PropertyGroup Label="UserMacros" />'
      w.write_raw(@pg2)
      w.write_raw(@idg)

      item_group(w) do
        #w.write_raw(src_area)
      end
=begin
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
=end
      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />'

      import_group(w, label: :ExtensionTargets) do
=begin
        @extension_targets.each do |et|
          w << "    <Import Project=\"#{et}\" />"
        end
        if @masm_required
          w << '    <Import Project="$(VCTargetsPath)\BuildCustomizations\masm.targets" />'
        end
=end
      end

      each_config do |cfg|
        # TODO: extension targets
      end
      w << "</Project>"
      w.chomp!
      file.write
    end

    def tools_version
      "17.0" # TODO
      #@host.attrs.version_year < 2013 ? '4.0' : @host.attrs.version
    end

    # See https://docs.microsoft.com/en-us/cpp/build/reference/vcxproj-filters-files?view=vs-2019
    def write_vcxproj_filters
    end
  end
end
