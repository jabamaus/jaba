SUPPORTED_PLATFORMS = [:win32, :x64, :iOS, :macOS].freeze

define :platform do

  help 'Represents a target platform'

  SUPPORTED_PLATFORMS.each do |p|
    attr "#{p}?", type: :bool do
      flags :expose
    end
  end
  
  attr :windows?, type: :bool do
    flags :expose
  end
  attr :apple?, type: :bool do
    flags :expose
  end
  attr :vsname
  
end

platform :win32 do
  win32? true
  windows? true
  vsname 'Win32'
end

platform :x64 do
  x64? true
  windows? true
  vsname 'x64'
end

platform :iOS do
  iOS? true
  apple? true
end

platform :macOS do
  macOS? true
  apple? true
end
