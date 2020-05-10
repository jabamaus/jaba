define :cpp do

  include :project_common

  help 'TODO'

  # TODO: should this be a reference as well as platform_ref, for validation
  attr_array :platforms do
    flags :required
  end
  
  attr :platform do
    flags :read_only
  end
    
  attr :platform_ref, type: :reference do
    referenced_type :platform
  end

  attr_array :hosts do
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
  end
  
  attr_array :deps, type: :reference do
    referenced_type :cpp
  end
  
  attr_hash :vcglobal do
    keyval_options :condition
  end
  
  attr :winsdkver, type: :choice do
    items ['10.0.16299.0', '10.0.17763.0']
    default '10.0.17763.0'
  end
  
  define :cpp_config do

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

    attr :exceptions, type: :bool do
      help 'Enables C++ exceptions. On by default.'
      flag_options :structured # Windows only
      default true
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
      keyval_options :group
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

  end

end
