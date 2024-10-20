require 'rexml'

module JABA
  class VcxprojConverter
    def initialize(vcxproj)
      @vcxproj = vcxproj
      @src_files = []
      @headers = []
      @projname = nil
      @type = nil
      @pch = nil
    end

    def run
      xml = IO.read(@vcxproj)
      doc = REXML::Document.new(xml)
      doc.elements.each("Project/PropertyGroup") do |e|
        if e.attributes['Label'] == 'Globals'
          pn = e.elements["ProjectName"]
          @projname = pn.text if pn
        elsif e.attributes['Label'] == 'Configuration'
          type = e.elements["ConfigurationType"]
          if type
            type = type.text
            if @type && @type != type
              JABA.error("Mixed type not yet supported")
            end
            @type = type
          end
        elsif e.attributes['Label'] == 'UserMacros'
        else # PropertyGroup with no attributes
        end
      end
      doc.elements.each("Project/ItemDefinitionGroup") do |e|
        e.elements.each do |group|
          case group.name
          when 'ClCompile'
            pch = group.elements["PrecompiledHeaderFile"]
            if pch
              pch = pch.text.to_forward_slashes
              if @pch && @pch != pch
                JABA.error("Mixed pchs not supported")
              end
              @pch = pch
            end
          when 'Link'
          end
        end
      end
      doc.elements.each("Project/ItemGroup") do |e|
        if e.attributes["Label"] == 'ProjectConfigurations'
        else
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
                JABA.warn("Unhandled file type '#{file}'")
              end
            when 'MASM'
              # TODO
            when 'ResourceCompile'
              # TODO
            else
              JABA.warn("Unhandled ItemGroup type '#{c.name}'")
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
    
    def get_cfg(elem)
      condition = elem.attributes['Condition']
      return nil if condition !~ /^'\$\(Configuration\)/
      if condition !~ /'\$\(Configuration\)\|\$\(Platform\)'=='(.+)'/
        raise "Failed to extract configuration from #{condition}"
      end
      $1
    end
  end
end
