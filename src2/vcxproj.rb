module JABA
  class Vcxproj
    include VSUtilities

    def initialize(target_node)
      @node = target_node
    end

    def process
      @projname = @node[:projname]
      @projdir = @node[:projdir]
      @vcxproj_file = "#{@projdir}/#{@projname}.vcxproj"
      @vcxproj_filters_file = "#{@vcxproj_file}.filters"
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
      end

      w << XMLVERSION
      w << "<Project DefaultTargets=\"Build\" ToolsVersion=\"#{tools_version}\" xmlns=\"#{XMLNS}\">"

      item_group(w, label: :ProjectConfigurations) do
        w.write_raw(@pc)
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
