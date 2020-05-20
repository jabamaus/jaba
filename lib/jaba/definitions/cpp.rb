define :cpp do

  help 'Cross platform C++ project definition'

  attr :root, type: :dir do
    help 'Root of the project specified as a relative path to the file that contains the project definition. ' \
         'All paths are specified relative to this. Project files will be generated here unless <projroot> is set.'
    default '.'
  end

  attr_array :platforms, type: :choice do
    items all_instance_ids(:platform)
    flags :required
  end

  define :target_platform do

    attr :platform, type: :symbol do
      flags :read_only
    end
      
    attr :platform_ref, type: :reference do
      referenced_type :platform
    end
  
    attr_array :hosts, type: :choice do
      items all_instance_ids(:host)
      flags :required
    end

    define :project do

      attr :projroot, type: :dir do
        help 'Directory in which projects will be generated. Specified as a relative path from <root>. If not specified ' \
        'projects will be generated in <root>'
        default '.'
        flags :no_check_exist # May get created during generation
      end
      
      attr :projname do
        help 'Seeds file basename of project files. Defaults to <name><projsuffix>.'
        default { "#{_ID}#{projname_suffix}" }
      end

      attr :projname_suffix do
        help 'Optional suffix to be applied to <projname>. Has no effect if <projname> is set explicitly.'
      end

      attr_array :src, type: :path do
        help 'Source file specification'
        flags :unordered # Final source will be sorted so no need to sort this
        flag_options :export
      end
      
      attr :host, type: :symbol do
        flags :read_only
      end

      attr :host_ref, type: :reference do
        referenced_type :host
      end

      attr :type, type: :choice do
        items [:app, :lib, :dll]
        default :app
      end
      
      attr_array :configs, type: :symbol do
        flags :required, :unordered
        flag_options :export
      end
      
      attr_array :deps, type: :reference do
        referenced_type :cpp
        make_handle do |id|
          "cpp|#{id}|#{platform}|#{host}"
        end
      end
      
      attr_hash :vcglobal do
        value_option :condition
        flag_options :export
      end
      
      attr :winsdkver, type: :choice do
        items ['10.0.16299.0', '10.0.17763.0']
        default '10.0.17763.0'
      end
      
      define :config do

        attr_array :build_action, type: :string do
          help 'Build actions'
          flag_options :export
          value_option :msg
          value_option :type, required: true, items: [:PreBuild, :PreLink, :PostBuild]
        end

        attr_array :cflags do
          help 'Compiler command line arguments'
          flag_options :export
        end

        attr :config, type: :symbol do
          flags :read_only
        end

        attr :config_name do
          help 'Display name of config in Visual Studio. Defaults to <config>.'
          default { config }
        end

        attr :debug, type: :bool do
          help 'Flags config as a debug build. Defaults to true if config id contains \'debug\''
          default do
            config =~ /debug/i ? true : false
          end
        end

        attr_array :defines, type: :string do
          help 'Preprocessor defines'
          flag_options :export
        end

        attr :exceptions, type: :choice do
          help 'Enables C++ exceptions. On by default.'
          items [true, false]
          items [:structured] # Windows only
          default true
        end

        attr_array :inc, type: :dir do
          help 'Include paths'
          flags :unordered
          flag_options :export
        end

        attr :rtti, type: :bool do
          default true
        end

        attr :toolset, type: :string do
          default { host_ref.toolset }
        end

        attr :unicode, type: :bool do
          help 'Enables unicode. On by default.'
          default true
        end

        attr_hash :vcproperty do
          value_option :group, required: true
          value_option :condition
          flag_options :export
        end

        attr :warnerror, type: :bool do
          help 'Enable warnings as errors. Off by default.'
        end
      end
    end
  end

end
