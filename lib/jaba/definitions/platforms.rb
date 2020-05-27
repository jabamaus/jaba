SUPPORTED_PLATFORMS = [:windows, :iOS, :macOS].freeze

define :platform do

  help 'Represents a target platform'

  SUPPORTED_PLATFORMS.each do |p|
    attr "#{p}?", type: :bool do
      help "Returns true if current platform is #{p}"
      flags :expose
    end
  end
  
  attr :microsoft?, type: :bool do
    help 'True if its a Microsoft platform'
    flags :expose
  end

  attr :apple?, type: :bool do
    help 'True if its an Apple platform'
    flags :expose
  end
  
  attr_array :valid_archs, type: :choice do
    help 'List of architectures supported by this platform'
    items all_instance_ids(:arch)
    flags :required, :nosort
  end

  attr_array :default_archs, type: :choice do
    help 'List of default target architectures for this platform'
    items all_instance_ids(:arch)
    flags :required, :nosort
  end

end

platform :windows do
  windows? true
  microsoft? true
  valid_archs [:x86, :x86_64, :arm64]
  default_archs [:x86, :x86_64]
end

platform :iOS do
  iOS? true
  apple? true
  valid_archs [] # TODO
  default_archs [] # TODO
end

platform :macOS do
  macOS? true
  apple? true
  valid_archs [] # TODO
  default_archs [] # TODO
end

SUPPORTED_ARCHS = [:x86, :x86_64, :arm64].freeze

define :arch do
  
  help 'Represents a target architecture'

  SUPPORTED_ARCHS.each do |a|
    attr "#{a}?", type: :bool do
      help "Returns true if current architecture is #{a}"
      flags :expose
    end
  end

  attr :little_endian?, type: :bool do
    flags :expose, :required
  end

  attr :big_endian?, type: :bool do
    flags :expose
    default { !little_endian? }
  end

  attr :vsname do
    flags :expose
    help 'Name of target architecture (platform) as seen in Visual Studio IDE'
  end

end

arch :x86 do
  x86? true
  vsname 'Win32'
  little_endian? true
end

arch :x86_64 do
  x86_64? true
  vsname 'x64'
  little_endian? true
end

arch :arm64 do
  arm64? true
  vsname 'ARM64'
  little_endian? true
end
