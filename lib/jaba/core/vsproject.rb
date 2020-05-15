# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class VSProject < Project
  
    ##
    #
    def init
      @guid = nil
      @host = @attrs.host_ref
      @platform = @attrs.platform_ref
      @platform_vsname = @platform.attrs.vsname
    end
    
    ##
    #
    def tools_version
      @host.attrs.version_year < 2013 ? '4.0' : @host.attrs.version
    end
    
    ##
    #
    def guid
      if !@guid
        if File.exist?(@vcxproj_file)
          if @services.read_file(@vcxproj_file, encoding: 'UTF-8') !~ /<ProjectGuid>(.+)<\/ProjectGuid>/
            @services.jaba_error("Failed to read GUID from #{@vcxproj_file}")
          end
          @guid = Regexp.last_match(1)
        else
          @guid = OS.generate_guid
        end
        @guid.freeze
      end
      @guid
    end
    
    ##
    #
    def write_xml_version(w)
      w << "\uFEFF<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    end
    
    ##
    #
    def xmlns
      'http://schemas.microsoft.com/developer/msbuild/2003'
    end
    
    ##
    #
    def xml_group(w, tag, label: nil, condition: nil, close: false, depth: 1)
      if !close
        w.write_raw "#{'  ' * depth}<#{tag}"
        w.write_raw " Label=\"#{label}\"" if label
        w.write_raw " Condition=\"#{condition}\"" if condition
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

    ##
    #
    def item_group(w, **options, &block)
      xml_group(w, 'ItemGroup', **options, &block)
    end
    
    ##
    #
    def property_group(w, **options, &block)
      xml_group(w, 'PropertyGroup', **options, &block)
    end
    
    ##
    #
    def import_group(w, **options, &block)
      xml_group(w, 'ImportGroup', **options, &block)
    end
    
    ##
    #
    def item_definition_group(w, **options, &block)
      xml_group(w, 'ItemDefinitionGroup', **options, &block)
    end
    
    ##
    #
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
    
    ##
    #
    def write_keyvalue(w, key, val, condition: nil, depth: 2)
      return if val.nil?
      w << if condition
              "#{'  ' * depth}<#{key} Condition=\"#{condition}\">#{val}</#{key}>"
            else
              "#{'  ' * depth}<#{key}>#{val}</#{key}>"
            end
    end

    ##
    #
    def cfg_condition(cfg)
      "'$(Configuration)|$(Platform)'=='#{cfg.attrs.config_name}|#{@platform_vsname}'"
    end
    
  end
  
end
