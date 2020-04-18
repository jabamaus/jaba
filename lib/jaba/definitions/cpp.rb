define :cpp do

  include :project

  help 'TODO'

  attr_array :platforms, type: :reference do
    referenced_type :platform
    flags :unordered
    default [:win32]
  end
  
  attr :platform do
    flags :read_only
  end
    
  attr_array :hosts, type: :reference do
    referenced_type :host
    default [:vs2017]
  end
  
  attr :host do
    flags :read_only
  end

  attr :type, type: :choice do
    items [:app, :lib, :dll]
    default :app
  end
  
  attr_array :configs do
    flags :unordered
    default [:debug, :release]
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
  
end

shared :config do
  
  attr :config do
    flags :read_only
  end

  attr :rtti, type: :bool do
    default true
  end

  attr :toolset do
    default { host_toolset }
  end

end

define :vsconfig do
  
  include :config

  help 'TODO'
  
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
