# frozen_string_literal: true

# TODO: add help string to flags
attr_flag :allow_dupes
attr_flag :no_check_exist
attr_flag :read_only
attr_flag :required
attr_flag :unordered

# TODO: think about compatibility of flags to attribute types, eg :no_make_rel_to_genroot only applies to
# :path, :file and :dir attrs

##
#
attr_type :bool do
  init_attr_def do
    default false
    flags :unordered, :allow_dupes
  end
  
  validate_value do |value|
    if !value.boolean?
      raise ':bool attributes only accept [true|false]'
    end
  end
end

##
#
attr_type :choice do
  init_attr_def do
    add_property :items, []
  end
  
  validate_attr_def do
    if items.empty?
      raise "'items' must be set"
    end
  end
  
  validate_value do |value|
    if !items.include?(value)
      raise "must be one of #{items}"
    end
  end
end

##
#
attr_type :dir do
end

##
#
attr_type :file do
end

##
#
attr_type :path do
end

##
#
attr_type :keyvalue do
  init_attr_def do
    default KeyValue.new
  end
end

##
#
attr_type :reference do
  init_attr_def do
    add_property :referenced_type, nil
  end
  
  validate_attr_def do
    rt = referenced_type
    if rt.nil?
      raise "'referenced_type' must be set"
    end
    if jaba_type.type != rt
      jaba_type.dependencies rt
    end
  end
end

SUPPORTED_PLATFORMS = [:win32, :x64, :iOS, :macOS].freeze

##
#
define :platform do

  SUPPORTED_PLATFORMS.each do |p|
    attr "#{p}?", type: :bool
  end
  
  attr :windows?, type: :bool
  attr :apple?, type: :bool
  attr :vsname
  
end

##
#
platform :win32 do
  win32? true
  windows? true
  vsname 'Win32'
end

##
#
platform :x64 do
  x64? true
  windows? true
  vsname 'x64'
end

##
#
platform :iOS do
  iOS? true
  apple? true
end

##
#
platform :macOS do
  macOS? true
  apple? true
end

SUPPORTED_VS_VERSIONS = [2010, 2012, 2013, 2015, 2017, 2019].freeze

##
#
define :host do

  attr :visual_studio?, type: :bool
  attr :xcode?, type: :bool
  attr :host_major_version
  attr :host_version
  attr :host_version_year
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
end

##
#
host :vs2012 do
  include :vscommon
  vs2012? true
  host_major_version 11
  host_version '11.0'
  host_version_year 2012
end

##
#
host :vs2013 do
  include :vscommon
  vs2013? true
  host_major_version 12
  host_version '12.0'
  host_version_year 2013
end

##
#
host :vs2015 do
  include :vscommon
  vs2015? true
  host_major_version 14
  host_version '14.0'
  host_version_year 2015
end

##
#
host :vs2017 do
  include :vscommon
  vs2017? true
  host_major_version 15
  host_version '15.0'
  host_version_year 2017
end

##
#
host :vs2019 do
  include :vscommon
  vs2019? true
  host_major_version 16
  host_version '16.0'
  host_version_year 2019
end

##
#
host :xcode do
  xcode? true
end

##
#
define :category do
  
  attr :name do
    help 'Display name of category. Maps to name of solution folder in a Visual Studio solution'
    flags :required
  end
  
  attr :guid do
    help 'A Globally Unique ID in the form \'0376E589-F783-4B80-DA86-705F2E05304E\'. Required by Visual Studio .sln files'
    flags :required
    validate do |val|
      if val !~ /[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/
        raise 'Must be an all upper case GUID in the form 0376E589-F783-4B80-DA86-705F2E05304E'
      end
    end
  end
  
  attr :parent, type: :reference do
    help 'Makes this category a child of the specified category.'
    referenced_type :category
  end
  
end

##
#
define :text do
  
  attr :filename, type: :file do
    help 'Path to the filename to be generated'
    flags :required
  end
  
  attr :content do
    help 'Directly set content of file as a string'
  end
  
  attr_array :line do
    help 'Set content of file line by line'
    flags :allow_dupes, :unordered
  end
  
  attr :eol, type: :choice do
    help 'Newline style'
    items [:lf, :crlf, :native]
    default :native
  end
  
end

##
#
define :project do
  
  attr :root, type: :dir do
    help 'Root of the project specified as a relative path to the file that contains the project definition. ' \
         'All paths are specified relative to this. Project files will be generated here unless the genroot ' \
         'attribute is used.'
    default '.'
  end

  attr :genroot, type: :dir do
    help 'Directory in which projects will be generated. Specified as a relative path from <root>. If not specified ' \
     'projects will be generated in <root>'
    default '.'
    flags :no_check_exist
  end
  
  attr :name do
    help 'The name of the project. Defaults to the definition id if not set.'
    default { "#{id}#{namesuffix}" }
  end
  
  attr :namesuffix do
    help 'Optional suffix to be applied to project name. Used by <name> by default but will have no effect ' \
         'if <name> is set explicitly'
  end
  
  attr_array :src, type: :path do
  end
  
end

##
#
define :cpp, extend: :project do

  attr_array :platforms, type: :reference do
    referenced_type :platform
    flags :unordered, :required
  end
  
  attr :platform do
  end
    
  attr_array :hosts, type: :reference do
    referenced_type :host
  end
  
  attr :host do
  end

  attr_array :targets do
    help 'Targets'
    flags :required, :unordered
  end
  
  attr_array :vcglobal, type: :keyvalue do
    keyval_options :condition
  end
end

##
#
define :vcxproj, extend: :project do
  
  attr :platform, type: :reference do
    referenced_type :platform
    default :win32
  end
  
  attr :host, type: :reference do
    referenced_type :host
    default :vs2017
  end
  
  attr_array :vcglobal, type: :keyvalue do
    keyval_options :condition
  end

  attr_array :configs do
    flags :required, :unordered
  end
  
  attr :config do
    flags :read_only
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
  
  attr_array :deps, type: :reference do
    referenced_type :vcxproj
  end
  
end

##
#
define :workspace do
end
