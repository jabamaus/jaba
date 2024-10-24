require 'rexml'
require 'rexml/xpath'

module JABA
  class VcxprojConverter

    Config = Struct.new(:name, :properties)

    def initialize(vcxproj, outdir)
      @vcxproj = vcxproj
      @vcxproj_dir = File.expand_path(vcxproj).parent_path
      @outdir = outdir
      @src_files = []
      @headers = []
      @projname = nil
      @configs = []
      @common_vcprops = {}
    end

    def error(msg)
      JABA.error("In #{@vcxproj.basename}: #{msg}")
    end
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
          @configs << Config.new(cfg, {})
        else
          error "Unhandled platform '#{platform}'"
        end
      end
      if @configs.empty?
        error "No configurations were extracted"
      end

      doc.elements.each("Project/PropertyGroup") do |e|
        # config can be on parent property group or individual properties
        parent_cfg = cfg_from_condition(e, fail_if_not_found: false)
        label = e.attributes['Label']
        case label
        when 'Globals'
          pn = e.elements["ProjectName"]
          @projname = pn.text if pn
        when 'Configuration', nil # PG1 Contains ConfigurationType
          group = label.nil? ? "PG2" : "PG1"
          e.elements.each do |p|
            cfg = parent_cfg ? parent_cfg : cfg_from_condition(p, fail_if_not_found: false)
            insert_property(p, group, cfg, p.name, p.text)
          end
        when 'UserMacros' # Ignore
        else
          error "Unhanded PropertyGroup label '#{label}'"
        end
      end
      doc.elements.each("Project/ItemDefinitionGroup") do |e|
        condition = e.attributes["Condition"]
        cfg = case condition
        when /'\$\(Configuration\)\|\$\(Platform\)'==/
          cfg_from_condition(e)
        else
          warn "Unhandled condition #{condition} in #{e.name}"
        end
        next if !cfg
        e.elements.each do |group|
          case group.name
          when 'ClCompile', 'Link'
            group.elements.each do |p|
              insert_property(p, group.name, cfg, p.name, p.text)
            end
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
        if e.attributes["Label"].nil?
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
              error "Unhandled ItemGroup type '#{c.name}'"
            end
          end
        end
      end
      
      if @projname.nil?
        @projname = @vcxproj.basename_no_ext
      end

      find_commonality

      common_src_prefix = process_src(@src_files)
      common_header_prefix = process_src(@headers)

      fn = "#{@projname}.jaba"
      puts "Generating #{fn}..."

      fm = FileManager.new
      fm.new_file(File.expand_path("#{@outdir}/#{fn}")) do |w|
        w << "target :#{@projname} do"
        write_src(w, @src_files, common_src_prefix)
        w << ""
        write_src(w, @headers, common_header_prefix)
        w.newline
        @common_vcprops.each do |vcprop, val|
          jaba_attr = vcprop_to_jaba_attr(vcprop)
          if jaba_attr.nil?
            w << "  vcprop '#{vcprop}', #{val}"
          elsif jaba_attr != :ignore
            attr_val = transform_vcprop_value(vcprop, jaba_attr, val)
            w << "  #{jaba_attr} #{attr_val}"
          end
        end
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
    
    def vcprop_to_jaba_attr(vcprop)
      case vcprop
      when 'ClCompile|AdditionalIncludeDirectories'
        :inc
      when 'ClCompile|PreprocessorDefinitions'
        :define
      when 'ClCompile|WarningLevel'
        :vcwarnlevel
      when 'Link|AdditionalDependencies'
        :syslibs
      when *[
        'PG2|IntDir', # defer to jaba defaults
        'PG2|OutDir', # defer to jaba defaults
        'PG2|_ProjectFileVersion',
        'Link|SubSystem' # automatically set by jaba
        ]
        :ignore
      else
        nil
      end
    end

    def transform_vcprop_value(vcprop, jaba_attr, val)
      # Remove group eg ClCompile|AdditionalIncludeDirectories becomes AdditionalIncludeDirectories
      vcprop_name = vcprop.split("|")[1]
      # Remove trailing eg %(AdditionalIncludeDirectories) from all property values
      val.sub!("%(#{vcprop_name})", "")

      case jaba_attr
      when :define
        "[#{val.split(";").map(&:quote!).join(", ")}]"
      when :inc
        process_path_array(val)
      when :syslibs
        "[#{val.split(";").map(&:quote!).join(", ")}]"
      when :vcwarnlevel
        if val !~ /Level(\d)/
          error "Could not read warning level from '#{val}'"
        end
        $1.to_i
      else
        error "Unhandled jaba attr '#{jaba_attr}'"
      end
    end

    def process_path_array(val)
      paths = val.split(";").map do |p|
        demacroise(p)
        p.relative_path_from!(@outdir)
        p.quote!
      end
      "[#{paths.join(", ")}]"
    end
    
    def demacroise(val)
      val.gsub!("$(ProjectDir)", @vcxproj_dir)
    end

    def find_commonality
      first = @configs[0]
      first.properties.delete_if do |key, val|
        common = true
        1.upto(@configs.size - 1) do |i|
          other = @configs[i]
          if !other.properties.key?(key)
            common = false
            break
          end
        end
        if common
          1.upto(@configs.size - 1) do |i|
            other = @configs[i]
            other.properties.delete(key)
          end
          if @common_vcprops.key?(key)
            error "Duplicate common property '#{key}' detected"
          end
          @common_vcprops[key] = val
        end
        common # delete if common
      end
    end

    def cfg_from_condition(elem, fail_if_not_found: true)
      condition = elem.attributes['Condition']
      if condition !~ /'\$\(Configuration\)\|\$\(Platform\)'=='(.+)'/ && fail_if_not_found
        error "Failed to extract configuration from '#{condition}'"
      end
      $1
    end

    def insert_property(elem, group_name, cfg, name, value)
      return if value.nil? # Strip if no value
      error "Could not read property name from '#{elem}'" if name.nil?
      properties = @common_vcprops
      if cfg
        cfg = @configs.find{|c| c.name == cfg}
        error "Could not find '#{cfg}' config" if cfg.nil?
        properties = cfg.properties
      end
      key = "#{group_name}|#{name}"
      if properties.key?(key)
        error "Duplicate key '#{key}' detected in #{properties}"
      end

      value = case value
      when "true"
        true
      when "false"
        false
      else
        value
      end

      properties[key] = value
    end
  end
end
