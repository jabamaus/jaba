SUPPORTED_VS_VERSIONS = [2010, 2012, 2013, 2015, 2017, 2019].freeze

define :host do

  help 'Represents a host system, eg Visual Studio, Xcode'

  attr :visual_studio?, type: :bool do
    flags :expose
  end
  attr :xcode?, type: :bool do
    flags :expose
  end
  attr :major_version
  attr :version
  attr :version_year
  # TODO: if this is flagged as string attr validation fails as xcode does not have a toolset. Raises question of how nil
  # value are handled. Should all attributes have an explicit value? Or better there should be a way of flagging that xcode does not
  # support toolset
  attr :toolset

  SUPPORTED_VS_VERSIONS.each do |vs_year|
    attr "vs#{vs_year}?", type: :bool do
      flags :expose
    end
  end
  
end

shared :vscommon do
  visual_studio? true
end

host :vs2010 do
  include :vscommon
  vs2010? true
  major_version 10
  version '10.0'
  version_year 2010
  toolset 'v100'
end

host :vs2012 do
  include :vscommon
  vs2012? true
  major_version 11
  version '11.0'
  version_year 2012
  toolset 'v110'
end

host :vs2013 do
  include :vscommon
  vs2013? true
  major_version 12
  version '12.0'
  version_year 2013
  toolset 'v120'
end

host :vs2015 do
  include :vscommon
  vs2015? true
  major_version 14
  version '14.0'
  version_year 2015
  toolset 'v140'
end

host :vs2017 do
  include :vscommon
  vs2017? true
  major_version 15
  version '15.0'
  version_year 2017
  toolset 'v141'
end

host :vs2019 do
  include :vscommon
  vs2019? true
  major_version 16
  version '16.0'
  version_year 2019
  toolset 'v142'
end

host :xcode do
  xcode? true
  toolset :unsupported
end
