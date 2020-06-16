# TODO: make this a global
SUPPORTED_PLATFORMS = [:windows, :ios, :macos].freeze

define :platform do

  title 'Target platform'

  SUPPORTED_PLATFORMS.each do |p|
    attr "#{p}?", type: :bool do
      title "Queries target platform"
      help "Returns true if current platform is #{p}"
      flags :expose
    end
  end
  
  attr :microsoft?, type: :bool do
    help 'Returns true if its a Microsoft platform'
    flags :expose
  end

  attr :apple?, type: :bool do
    help 'Returns true if its an Apple platform'
    flags :expose
  end
  
  attr_array :valid_archs, type: :choice do
    title 'List of architectures supported by this platform'
    items all_instance_ids(:arch)
    flags :required, :nosort
  end

end

# windows platform instance for use in definitions
#
platform :windows do
  windows? true
  microsoft? true
  valid_archs [:x86, :x86_64, :arm64]
end

# ios platform instance for use in definitions
#
platform :ios do
  ios? true
  apple? true
  valid_archs [] # TODO
end

# macos platform instance for use in definitions
#
platform :macos do
  macos? true
  apple? true
  valid_archs [] # TODO
end
