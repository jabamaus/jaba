# frozen_string_literal: true

SUPPORTED_VS_VERSIONS = [2010, 2012, 2013, 2015, 2017, 2019].freeze

##
#
define :host do

  attr :visual_studio?, type: :bool
  attr :xcode?, type: :bool
  attr :host_major_version
  attr :host_version
  attr :host_version_year
  attr :host_toolset
  
  SUPPORTED_VS_VERSIONS.each do |vs_year|
    attr "vs#{vs_year}?", type: :bool
  end
  
end

shared :vscommon do
  visual_studio? true
end

##
#
host :vs2010 do
  include :vscommon
  vs2010? true
  host_major_version 10
  host_version '10.0'
  host_version_year 2010
  host_toolset 'v100'
end

##
#
host :vs2012 do
  include :vscommon
  vs2012? true
  host_major_version 11
  host_version '11.0'
  host_version_year 2012
  host_toolset 'v110'
end

##
#
host :vs2013 do
  include :vscommon
  vs2013? true
  host_major_version 12
  host_version '12.0'
  host_version_year 2013
  host_toolset 'v120'
end

##
#
host :vs2015 do
  include :vscommon
  vs2015? true
  host_major_version 14
  host_version '14.0'
  host_version_year 2015
  host_toolset 'v140'
end

##
#
host :vs2017 do
  include :vscommon
  vs2017? true
  host_major_version 15
  host_version '15.0'
  host_version_year 2017
  host_toolset 'v141'
end

##
#
host :vs2019 do
  include :vscommon
  vs2019? true
  host_major_version 16
  host_version '16.0'
  host_version_year 2019
  host_toolset 'v141'
end

##
#
host :xcode do
  xcode? true
end
