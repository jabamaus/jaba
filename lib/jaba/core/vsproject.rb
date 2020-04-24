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
      @host = @attrs.host
      @platform = @attrs.platform
    end
    
    ##
    #
    def dump_jaba_output(p_root)
      super
      p_root[:platform] = @platform
      p_root[:host] = @host
      p_root[:guid] = @guid
    end

    ##
    #
    def tools_version
      @host.attrs.host_version_year < 2013 ? '4.0' : @host.attrs.host_version
    end
    
    ##
    #
    def guid
      if !@guid
        if File.exist?(@vcxproj_file)
          if @services.read_file(@vcxproj_file, encoding: 'UTF-8') !~ /<ProjectGuid>(.+)<\/ProjectGuid>/
            raise "Failed to read GUID from #{@vcxproj_file}"
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
    def xml_group(w, tag, label: nil, condition: nil, depth: 1)
      w.write_raw "#{'  ' * depth}<#{tag}"
      w.write_raw " Label=\"#{label}\"" if label
      w.write_raw " Condition=\"#{condition}\"" if condition
      w << '>'
      yield
      w << "#{'  ' * depth}</#{tag}>"
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
      attr.each_value do |key_val, _options, key_val_options|
        if !group || group == key_val_options[:group]
          key = key_val.key
          val = key_val.value
          condition = key_val_options[:condition]
          w << if condition
                 "#{'  ' * depth}<#{key} Condition=\"#{condition}\">#{val}</#{key}>"
               else
                 "#{'  ' * depth}<#{key}>#{val}</#{key}>"
               end
        end
      end
    end
    
    ##
    #
    def cfg_condition(cfg)
      "'$(Configuration)|$(Platform)'=='#{cfg.attrs.config_name}|#{@platform.attrs.vsname}'"
    end
    
  end
  
end
