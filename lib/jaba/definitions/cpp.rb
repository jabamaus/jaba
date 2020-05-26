define :cpp do

  help 'Cross platform C++ project definition'

   attr_array :hosts, type: :choice do
    items all_instance_ids(:host)
    flags :required
  end
  
  attr :root, type: :dir do
    help 'Root of the project specified as a relative path to the file that contains the project definition. ' \
         'All paths are specified relative to this. Project files will be generated here unless <projroot> is set.'
    default '.'
  end

  define :per_host do

    # Required attributes that the user must provide a value for.
    #
    attr_array :platforms, type: :choice do
      items all_instance_ids(:platform) # TODO: should only allow platforms supported by this host
      flags :required
    end
    
    # Control flow attributes
    #
    attr :host, type: :symbol do
      flags :read_only
    end

    attr :host_ref, type: :reference do
      referenced_type :host
    end

  end

  define :per_platform do

    # Required attributes that the user must provide a value for.
    #
    attr_array :archs, type: :choice  do
      items all_instance_ids(:arch) # TODO: should be valid_archs for current platform
      flags :required
    end

    attr_array :configs, type: :symbol_or_string do
      flags :required, :unordered
      flag_options :export
    end

    # Control flow attributes
    #
    attr :platform, type: :symbol do
      flags :read_only
    end
      
    attr :platform_ref, type: :reference do
      referenced_type :platform
    end
  
    # Common attributes
    #
    attr_array :deps, type: :reference do
      help 'Specify project dependencies. List of ids of other cpp definitions.'
      referenced_type :cpp
      make_handle do |id|
        "cpp|#{id}|#{host}|#{platform}"
      end
    end

    attr :projroot, type: :dir do
      help 'Directory in which projects will be generated. Specified as a relative path from <root>. If not specified ' \
      'projects will be generated in <root>'
      default '.'
      flags :no_check_exist # May get created during generation
    end
    
    attr :projname, type: :symbol_or_string do
      help 'Seeds file basename of project files. Defaults to <name><projsuffix>.'
      default { "#{_ID}#{projname_suffix}" }
    end

    attr :projname_suffix, type: :symbol_or_string do
      help 'Optional suffix to be applied to <projname>. Has no effect if <projname> is set explicitly.'
    end

    attr :winsdkver, type: :choice do
      help 'Windows SDK version. Defaults to nil.'
      items [
        '10.0.16299.0',  # Included in VS2017 ver.15.4
        '10.0.17134.0',  # Included in VS2017 ver.15.7
        '10.0.17763.0',  # Included in VS2017 ver.15.8
        '10.0.18362.0',  # Included in VS2019
        nil
      ]
      default nil
    end

    attr_hash :vcglobal do
      help 'Directly address the Globals property group in a vcxproj'
      value_option :condition
      flag_options :export
    end

  end

  define :per_arch do

    attr :arch, type: :symbol_or_string do
      help 'Returns current arch being processed. Use to define control flow to set config-specific atttributes'
      flags :read_only
    end

    attr :arch_ref, type: :reference do
      referenced_type :arch
    end

    attr_array :src, type: :path do
      help 'Source file specification'
      flags :unordered # Final source will be sorted so no need to sort this
      flag_options :export
    end
    
  end

  # Sub-grouping of attributes that pertain to a build configuration
  #
  define :config do

    # Required attributes that the user must provide a value for.
    #
    attr :type, type: :choice do
      items [:app, :console, :lib, :dll]
      flags :required
    end

    # Control flow attributes
    #
    attr :config, type: :symbol_or_string do
      help 'Returns current config being processed. Use to define control flow to set config-specific atttributes'
      flags :read_only
    end

    # Common attributes. These are the attributes that most definitions will set/use.
    #
    attr_array :build_action, type: :string do
      help 'Build action, eg a prebuild step'
      flag_options :export
      value_option :msg
      value_option :type, required: true, items: [:PreBuild, :PreLink, :PostBuild]
    end

    attr_array :cflags do
      help 'Raw compiler command line switches'
      flag_options :export
    end

    attr :config_name do
      help 'Display name of config in Visual Studio. Defaults to <config>'
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

    attr_array :inc, type: :dir do
      help 'Include paths'
      flags :unordered
      flag_options :export
    end

    attr :warnerror, type: :bool do
      help 'Enable warnings as errors. Off by default.'
    end

    # Not so common attributes. Often used but not fundamental.
    #
    attr :character_set, type: :choice do
      help 'Character set. Defaults to :unicode'
      items [
        :mbcs,    # Visual Studio only
        :unicode,
        nil
      ]
      default nil
    end

    attr :exceptions, type: :choice do
      help 'Enables C++ exceptions. On by default.'
      items [true, false]
      items [:structured] # Windows only
      default true
    end

    attr :rtti, type: :bool do
      help 'Enable runtime type information. On by default.'
      default true
    end

    attr :toolset, type: :string do
      default { host_ref.toolset }
    end

    attr_hash :vcproperty do
      help 'Address config section of a vcxproj directly'
      value_option :group, required: true
      value_option :condition
      flag_options :export
    end

  end

end
