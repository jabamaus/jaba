define :cpp do

  include :project_common

  help 'TODO'

  attr_array :platforms do
    flags :required
  end
  
  attr :platform, type: :reference do
    referenced_type :platform
    flags :read_only
  end
    
  attr_array :hosts do
    flags :required
  end
  
  attr :host, type: :reference do
    referenced_type :host
    flags :read_only
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
  
  attr_array :vcglobal, type: :keyvalue do
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
      default { host_toolset }
    end

    attr :unicode, type: :bool do
      help 'Enables unicode. On by default.'
      default true
    end

    attr_array :vcproperty, type: :keyvalue do
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
