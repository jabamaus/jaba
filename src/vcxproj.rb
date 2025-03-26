module JABA
  SrcFileInfo = Data.define(
    :absolute_path,
    :projdir_rel,
    :vpath,
    :file_type,
    :extname,
    :properties
  )

  class Vcxproj
    include VSUtilities

    @@project_builder = {}
    @@config_builder = {}

    def self.project_builder(platform, &block) = @@project_builder[platform] = block
    def self.config_builder(platform, &block) = @@config_builder[platform] = block

    def initialize(target_node)
      @node = target_node
      @projname = @node[:projname]
      @projdir = @node[:projdir]
      @vcxproj_file = "#{@projdir}/#{@projname}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
      @guid = @node[:vcguid]
      @extension_settings = []
      @extension_targets = []
      @src = []
      @src_lookup = {}
      @file_type_hash = JABA.context.root_node[:vcfiletype]
      @file_to_file_type = {}
      @dependencies = []
    end

    def node = @node
    def projname = @projname
    def projdir = @projdir
    def vcxproj_file = @vcxproj_file
    def guid = @guid
    def dependencies = @dependencies

    def init_dependencies
      deps = @node.get_attr(:deps)
      deps.each do |attr|
        dep_node = attr.value
        soft = attr.option_value(:type) == :soft
        if !soft
          proj = JABA.context.lookup_project(dep_node)
          @dependencies << proj
        end
      end
    end

    def generate
      platform = @node[:platform]
      pb = @@project_builder[platform]
      JABA.error("No vcxproj project builder for '#{platform.inspect_unquoted}' platform") if pb.nil?

      cb = @@config_builder[platform]
      JABA.error("No vcxproj config builder for '#{platform.inspect_unquoted}' platform") if cb.nil?

      @node.eval_jdl(self, &pb)

      @node.each_config do |cfg|
        cfg.eval_jdl(self, cfg[:type], &cb)
        src_attr = cfg.get_attr(:src)
        vcprop_attr = cfg.get_attr(:vcprop)
        vsplatform = "x64" # TODO: cfg.attrs.arch.attrs.vsname
        cfg_name = cfg[:configname]

        pchsrc_attr = cfg.get_attr(:pchsrc)
        pchsrc = pchsrc_attr.value
        if !pchsrc.empty?
          cfg.get_attr(:src).set pchsrc, properties: {PrecompiledHeader: :Create}
        end

        shell_cmds = {}
        cfg.get_attr(:shell).each do |attr|
          value = attr.value
          type = attr.option_value(:when)
          group = "#{type}Event"
          shell_cmds.push_value(group, value)
        end

        shell_cmds.each do |group, cmds|
          vcprop_attr.set("#{group}|Command", cmds.join("\n"))
        end

        cfg[:rule].each do |rule|
          input_attr_array = rule.get_attr(:input)
          output_attr = rule.get_attr(:output)
          output = output_attr.value
          output_vpath = output_attr.option_value(:vpath)
          output_properties = output_attr.option_value(:properties) || {}
          imp_input = rule[:implicit_input]
          imp_input = nil if imp_input.empty?
          cmd_attr = rule.get_attr(:cmd)
          cmd = cmd_attr.value
          cmd_abs = cmd_attr.has_flag_option?(:absolute)
          msg = rule[:msg]

          input_attr_array.each do |input_attr|
            input = input_attr.value
            input_vpath = input_attr.option_value(:vpath)
            @file_to_file_type[input] = :CustomBuild
            d_output = demacroise(output, input, imp_input, nil)
            # output may not exist on disk so force
            if output_vpath
              src_attr.set(d_output, :force, vpath: output_vpath, properties: output_properties)
            else
              src_attr.set(d_output, :force, properties: output_properties)
            end
            input_rel = input.relative_path_from(@projdir, backslashes: true)
            imp_input_rel = imp_input ? imp_input.relative_path_from(@projdir, backslashes: true) : nil
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

            props = { FileType: :Document, Command: d_cmd, Outputs: output_rel }
            if imp_input
              props[:AdditionalInputs] = imp_input_rel
            end
            props[:Message] = d_msg
            if input_vpath
              src_attr.set(input, properties: props, vpath: input_vpath)
            else
              src_attr.set(input, properties: props)
            end
          end
        end

        src_attr.sort!
        src_attr.each do |sf_elem|
          sf = sf_elem.value
          sfi = @src_lookup[sf]
          if !sfi
            ext = sf.extname
            rel = sf.relative_path_from(@projdir, backslashes: true)
            ft = @file_to_file_type[sf]
            ft = @file_type_hash[sf.extname] if ft.nil?
            ft = :None if ft.nil?

            vpath = sf_elem.option_value(:vpath)

            # If no specified vpath then preserve the structure of the src files/folders. 
            # It is important that vpath does not start with ..
            #
            if vpath.nil?
              vpath = sf.parent_path.relative_path_from(@node.root, backslashes: true, nil_if_dot: true, no_dot_dot: true)
            end
            if vpath == '.'
              vpath = nil
            end
  
            sfi = SrcFileInfo.new(sf, rel, vpath, ft, ext, [])
            @src << sfi
            @src_lookup[sf] = sfi
          end
          sf_props = sf_elem.option_value(:properties)
          sf_props&.each do |name, val|
            sfi.properties << [name, cfg_name, vsplatform, val]
          end
        end
      end
      write_vcxproj
      write_vcxproj_filters
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
        if method && !method.empty? # mruby can give an empty string here whereas ruby gives nil
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
      file = JABA.context.file_manager.new_file(@vcxproj_file, eol: :windows, encoding: "UTF-8")
      w = file.writer
      @pc = file.work_area
      @pg1 = file.work_area
      @pg2 = file.work_area
      @ps = file.work_area
      @idg = file.work_area

      @node.each_config do |cfg|
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

        cfg.get_attr(:vcprop).each do |key, attr|
          group, key = key.split("|")
          condition = attr.option_value(:condition)
          val = attr.value

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
        file_props = sf.properties
        src_area.write_raw("    <#{ft} Include=\"#{sf.projdir_rel}\"")
        if !file_props.empty?
          src_area << ">"
          file_props.each do |p|
            src_area << "      <#{p[0]} Condition=\"#{cfg_condition(p[1], p[2])}\">#{p[3]}</#{p[0]}>"
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

      @node.each_config do |cfg|
        # TODO: ExtensionSettings
      end

      w.write_raw(@ps)
      w << '  <PropertyGroup Label="UserMacros" />'
      w.write_raw(@pg2)
      w.write_raw(@idg)

      item_group(w) do
        w.write_raw(src_area)
      end

      if !@dependencies.empty?
        item_group(w) do
          @dependencies.each do |proj|
            w << "    <ProjectReference Include=\"#{proj.vcxproj_file.relative_path_from(projdir, backslashes: true)}\">"
            w << "      <Project>#{proj.guid}</Project>"
            # TODO: reference properties
            w << "    </ProjectReference>"
          end
        end
      end

      w << '  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />'

      import_group(w, label: :ExtensionTargets) do
        @extension_targets.each do |et|
          w << "    <Import Project=\"#{et}\" />"
        end
=begin
        if @masm_required
          w << '    <Import Project="$(VCTargetsPath)\BuildCustomizations\masm.targets" />'
        end
=end
      end

      @node.each_config do |cfg|
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
      file = JABA.context.file_manager.new_file(@vcxproj_filters_file, eol: :windows, encoding: 'UTF-8')
      w = file.writer

      w << XMLVERSION
      w << "<Project ToolsVersion=\"4.0\" xmlns=\"#{XMLNS}\">"
      
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
          w << "      <UniqueIdentifier>#{Kernel.psuedo_uuid_from_string(f, namespace: @vcxproj_file.basename, braces: true)}</UniqueIdentifier>"
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
