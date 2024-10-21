require 'rexml'
require 'rexml/xpath'

module JABA
  class VcxprojConverter
    def initialize(vcxproj)
      @vcxproj = vcxproj
      @src_files = []
      @headers = []
      @projname = nil
      @config_to_property = {}
    end

    def error(msg) = JABA.error("In #{@vcxproj.basename}: #{msg}")
    def warn(msg) = JABA.warn("In #{@vcxproj.basename}: #{msg}")

    def run
      xml = IO.read(@vcxproj)
      doc = REXML::Document.new(xml)
      REXML::XPath.each(doc, "//Project/ItemGroup[@Label='ProjectConfigurations']/ProjectConfiguration") do |e|
        cfg = e.attributes["Include"] 
        if cfg !~ /^.*\|(.*)$/
          error "Couldn't extract configuration from '#{cfg}'"
        end
        platform = $1
        case platform
        when 'x64', 'Win32'
          @config_to_property[cfg] = []
        else
          error "Unhandled platform '#{platform}'"
        end
      end
      if @config_to_property.empty?
        error "No configurations were extracted"
      end

      doc.elements.each("Project/PropertyGroup") do |e|
        case e.attributes['Label']
        when 'Globals'
          pn = e.elements["ProjectName"]
          @projname = pn.text if pn
        when 'Configuration' # Contains ConfigurationType
          cfg = cfg_from_condition(e)
          insert_properties(cfg, e)
        when 'UserMacros'
          # Ignore
        else # PropertyGroup with no attributes
        end
      end
      doc.elements.each("Project/ItemDefinitionGroup") do |e|
        condition = e.attributes["Condition"]
        cfg = case condition
        when /'\$\(Configuration\)\|\$\(Platform\)'==/
          cfg_from_condition(e)
        else
          warn "Unandled condition in #{e}"
        end
        next if !cfg
        e.elements.each do |group|
          case group.name
          when 'ClCompile', 'Link'
            insert_properties(cfg, group)
          when 'Midl'
            # nothing
          when 'ResourceCompile'
          when 'PreBuildEvent'
          when 'PostBuildEvent'
          else
            error "Unhandled ItemDefinitionGroup '#{group.name}'"
          end
        end
      end
      doc.elements.each("Project/ItemGroup") do |e|
        if e.attributes["Label"]
          e.elements.each do |c|
            case c.name
            when 'ClCompile', 'ClInclude'
              file = c.attributes['Include'].gsub("..\\", '').to_forward_slashes!
              case file
              when /\.(c|cpp)$/
                @src_files << file
              when /\.(h|hpp)$/
                @headers << file
              else
                warn "Unhandled file type '#{file}'"
              end
            when 'MASM'
              # TODO
            when 'ResourceCompile'
              # TODO
            when 'ProjectConfiguration'
              # already dealt with
            else
              warn "Unhandled ItemGroup type '#{c.name}'"
            end
          end
        end
      end
      
      if @projname.nil?
        @projname = @vcxproj.basename_no_ext
      end

      common_src_prefix = process_src(@src_files)
      common_header_prefix = process_src(@headers)

      fn = "#{@projname}.jaba"
      puts "Generating #{fn}..."

      fm = FileManager.new
      fm.new_file(File.expand_path(fn)) do |w|
        w << "target :#{@projname} do"
        write_src(w, @src_files, common_src_prefix)
        w << ""
        write_src(w, @headers, common_header_prefix)
        w << "end"
      end
      fm.report
    end

    def process_src(files)
      files.sort_no_case!
      prefix = files.common_path_prefix
      if prefix == '/'
        prefix = nil
      end
      if prefix
        @src_files.each do |f|
          f.delete_prefix!(prefix)
        end
      end
      prefix
    end

    def write_src(w, files, prefix)
      w << "  src %w("
      files.each do |f|
        w << "    #{f}"
      end
      w.write_raw "  )"
      if prefix
        w.write_raw ", prefix: '#{prefix}'"
      end
      w.newline
    end
    
    def cfg_from_condition(elem)
      condition = elem.attributes['Condition']
      if condition !~ /'\$\(Configuration\)\|\$\(Platform\)'=='(.+)'/
        error "Failed to extract configuration from '#{condition}'"
      end
      $1
    end

    def insert_properties(cfg, elem)
      elem.elements.each do |c|
        name = c.name
        value = c.text
        error "Could read property name from '#{elem}'" if name.nil?
        error "Could read property falue from '#{elem}'" if value.nil?
        @config_to_property.push_value(cfg, "<#{name}>#{value}")
      end
    end
  end
end
