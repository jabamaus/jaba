module JABA

  class VSProj
    include SrcFileSupport
    
    attr_reader :services
    attr_reader :attrs
    attr_reader :projdir
    attr_reader :host
    attr_reader :platform # In theory multiple platforms need to be supported...
    attr_reader :guid
    attr_reader :root

    def initialize(plugin, node)
      @plugin = plugin
      @services = plugin.services
      @node = node
      @attrs = node.attrs
      @projdir = @attrs.projdir
      @host = @attrs.host
      @platform = @attrs.platform
      @guid = @attrs.guid
      @root = @attrs.root
    end

    def handle = @node.handle

    # Required by SrcFileSupport
    #
    def want_backslashes? = true

    def tools_version
      @host.attrs.version_year < 2013 ? '4.0' : @host.attrs.version
    end
    
    def write_xml_version(w)
      w << "\uFEFF<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    end
    def xmlns = 'http://schemas.microsoft.com/developer/msbuild/2003'
    def xml_group(w, tag, label: nil, label_at_end: true, condition: nil, close: false, depth: 1)
      if !close
        w.write_raw "#{'  ' * depth}<#{tag}"
        w.write_raw " Label=\"#{label}\"" if (label && !label_at_end)
        w.write_raw " Condition=\"#{condition}\"" if condition
        w.write_raw " Label=\"#{label}\"" if (label && label_at_end)
        w << '>'
      end
      
      if block_given?
        yield
        close = true
      end

      if close
        w << "#{'  ' * depth}</#{tag}>"
      end
    end

    def item_group(w, **options, &block) = xml_group(w, 'ItemGroup', **options, &block)
    def property_group(w, **options, &block) = xml_group(w, 'PropertyGroup', **options, &block)
    def import_group(w, **options, &block) = xml_group(w, 'ImportGroup', **options, &block)
    def item_definition_group(w, **options, &block) =  xml_group(w, 'ItemDefinitionGroup', **options, &block)
    
    def write_keyvalue_attr(w, attr, group: nil, depth: 2)
      attr.visit_attr do |elem, val|
        if group
          group_option = elem.get_option_value(:group)
          next if group != group_option
        end
        key = elem.get_option_value(:__key)
        condition = elem.get_option_value(:condition, fail_if_not_found: false)
        write_keyvalue(w, key, val, condition: condition)
      end
    end
    
    def write_keyvalue(w, key, val, condition: nil, depth: 2)
      return if val.nil?
      w << if condition
              "#{'  ' * depth}<#{key} Condition=\"#{condition}\">#{val}</#{key}>"
            else
              "#{'  ' * depth}<#{key}>#{val}</#{key}>"
            end
    end

    def cfg_condition(cfg_name, platform)
      "'$(Configuration)|$(Platform)'=='#{cfg_name}|#{platform}'"
    end
  end
end
