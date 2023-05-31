module JABA
  SrcFileInfo = Data.define(
    :absolute_path,
    :projdir_rel,
    :vpath,
    :file_type,
    :extname
  )

  class Vcxproj
    include VSUtilities

    def initialize(target_node)
      @node = target_node
    end

    def projdir = @projdir

    def generate
      @projname = @node[:projname]
      @projdir = @node[:projdir]
      @vcxproj_file = "#{@projdir}/#{@projname}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
      @per_file_props = {}
      @extension_settings = []
      @extension_targets = []
      @src = []
      @src_set = Set.new
      @file_type_hash = JABA.context.root_node[:vcfiletype]
      @file_to_file_type = {}

      t = @node.node_def.jdl_builder.lookup_translator(:vcxproj_windows)
      @node.eval_jdl(self, &t)

      t = @node.node_def.jdl_builder.lookup_translator(:vcxproj_config_windows)

      each_config do |cfg|
        cfg.eval_jdl(self, cfg[:type], &t)
        src_attr = cfg.get_attr(:src)
        vcfprop_attr = cfg.get_attr(:vcfprop)

        cfg[:rule].each do |rule|
          output = rule[:output]
          imp_input = rule[:implicit_input]
          cmd_attr = rule.get_attr(:cmd)
          cmd = cmd_attr.value
          cmd_abs = cmd_attr.has_flag_option?(:absolute)
          msg = rule[:msg]

          rule[:input].each do |input|
            src_attr.set(input)
            @file_to_file_type[input] = :CustomBuild
            d_output = demacroise(output, input, imp_input, nil)
            src_attr.set(d_output, :force) # output may not exist on disk so force

            input_rel = input.relative_path_from(@projdir, backslashes: true)
            imp_input_rel = imp_input.relative_path_from(@projdir, backslashes: true)
            output_rel = d_output.relative_path_from(@projdir, backslashes: true)

            d_cmd = if cmd_abs
                demacroise(cmd, input, imp_input ? "$(ProjectDir)#{imp_input_rel}" : nil, d_output)
              else
                demacroise(cmd,
                           "$(ProjectDir)#{input_rel}",
                           imp_input ? "$(ProjectDir)#{imp_input_rel}" : nil,
                           "$(ProjectDir)#{output_rel}")
              end
            d_cmd = d_cmd.to_escaped_xml
            # Characters like < > | & are escaped to prevent unwanted behaviour when the msg is echoed
            d_msg = demacroise(msg, input, imp_input, d_output).to_escaped_DOS.to_escaped_xml

            vcfprop_attr.set("#{input}|FileType", :Document)
            vcfprop_attr.set("#{input}|Command", d_cmd)
            vcfprop_attr.set("#{input}|Outputs", output_rel)
            if imp_input
              vcfprop_attr.set("#{input}|AdditionalInputs", imp_input_rel)
            end
            vcfprop_attr.set("#{input}|Message", d_msg)
          end
        end

        src_attr.sort!
        src_attr.value.each do |sf|
          if @src_set.add?(sf)
            ext = sf.extname
            rel = sf.relative_path_from(@projdir, backslashes: true)
            ft = @file_to_file_type[sf]
            ft = @file_type_hash[sf.extname] if ft.nil?
            ft = :None if ft.nil?
            @src << SrcFileInfo.new(sf, rel, nil, ft, ext)
          end
        end
      end

      write_vcxproj
      write_vcxproj_filters
    end

    def each_config(&block) = @node.children.each(&block)

    def get_matching_src(abs_spec, fail_if_not_found: true, errobj: nil)
      JABA.error("'#{abs_spec.inspect_unquoted}' must be an absolute path") if !abs_spec.absolute_path?
      if abs_spec.wildcard?
        # Use File::FNM_PATHNAME so eg dir/**/*.c matches dir/a.c
        files = @src.select { |s| File.fnmatch?(abs_spec, s.absolute_path, File::FNM_PATHNAME) }
        if files.empty? && fail_if_not_found
          JABA.error("'#{spec}' did not match any files")
        end
        return files
      end
      s = @src.find { |s| s.absolute_path == abs_spec }
      if !s && fail_if_not_found
        JABA.error("'#{spec}' src file not in project", errobj: errobj)
      end
      [s] # Note that Array(s) did something unexpected - added all the struct elements to the array where the actual struct is wanted
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
        str.gsub!(full_var) { repl }
      end
      str
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

        cfg.visit_attr(:vcfprop) do |attr, val|
          file_with_prop, prop = attr.option_value(:__key).split("|")
          sfs = get_matching_src(file_with_prop, errobj: attr)
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

      src_area = file.work_area
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

        es = @node[:vc_extension_settings][sf.extname]
        if es
          @extension_settings << es.relative_path_from(projdir, backslashes: true)
        end
        et = @node[:vc_extension_targets][sf.extname]
        if et
          @extension_targets << et.relative_path_from(projdir, backslashes: true)
        end
        #if ft == :MASM
        #  @masm_required = true
        #end
      end

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
        w.write_raw(src_area)
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
