define :cpp do

  include :project_common

  help 'TODO'

  attr_array :platforms, type: :choice do
    items all_instance_ids(:platform)
    flags :required
  end
  
  attr :platform do
    flags :read_only
  end
    
  attr :platform_ref, type: :reference do
    referenced_type :platform
  end

  attr_array :hosts, type: :choice do
    items all_instance_ids(:host)
    flags :required
  end
  
  attr :host do
    flags :read_only
  end

  attr :host_ref, type: :reference do
    referenced_type :host
  end

  attr :type, type: :choice do
    items [:app, :lib, :dll]
    default :app
  end
  
  attr_array :configs do
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
    keyval_options :condition
    flag_options :export
  end
  
  attr :winsdkver, type: :choice do
    items ['10.0.16299.0', '10.0.17763.0']
    default '10.0.17763.0'
  end
  
  define :cpp_config do

    attr_array :build_action do
      help 'Build actions'
      flag_options :export
      keyval_options :msg, :type # :PreBuild, :PreLink, :PostBuild
    end

    attr_array :cflags do
      help 'Compiler command line arguments'
      flag_options :export
    end

    attr :config do
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

    attr_array :defines do
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

    attr :toolset do
      default { host_ref.toolset }
    end

    attr :unicode, type: :bool do
      help 'Enables unicode. On by default.'
      default true
    end

    attr_hash :vcproperty do
      keyval_options :group, :idg
      flag_options :export
=begin
      keyval_option :condition do
        validate do |value|
        end
      end
      keyval_option :group do
        flags :required
      end
=end
    end

    attr :warnerror, type: :bool do
      help 'Enable warnings as errors. Off by default.'
    end
  end

end
