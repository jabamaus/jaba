# TODO: add help string to flags
attr_flag :array
attr_flag :allow_dupes
attr_flag :no_check_exist
attr_flag :read_only
attr_flag :required
attr_flag :unordered

# TODO: think about compatibility of flags to attribute types, eg :no_make_rel_to_genroot only applies to :path, :file and :dir attrs

##
#
attr_type :bool do
  init_attr_def do
    default false
    flags :unordered, :allow_dupes
  end
  
  validate do |value|
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
  
  validate do |value|
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
end

##
#
attr_type :reference do
end

##
#
define :platform do
end

platform :win32 do
end

platform :x64 do
end

platform :ios do
end

platform :macos do
end

##
#
define :host do

  attr :visual_studio, type: :bool do
  end
  
  attr :xcode, type: :bool do
  end
  
end

[2008, 2013, 2015, 2017, 2019].each do |vs_year|
  host "vs#{vs_year}".to_sym do
    visual_studio true
  end
end

host :xcode do
  xcode true
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
  
  attr :line do
    help 'Set content of file line by line'
    flags :array, :allow_dupes, :unordered
  end
  
  attr :eol, type: :choice do
    help 'Newline style'
    items [:native, :unix, :windows]
    default :native
  end
  
  generate do
    str = content ? content : "#{line.join("\n")}\n"
    save_file(filename, str, eol)
  end
  
end

##
#
define :project do
  
  attr :platforms do
    flags :array, :unordered, :required
  end
  
  attr :root, type: :dir do
    help 'Root of the project specified as a relative path to the file that contains the project definition. ' \
         'All paths are specified relative to this. Project files will be generated here unless the genroot attribute is used.'
    default '.'
  end
  
  attr :genroot, type: :dir do
    help 'Directory in which projects will be generated. Specified as a relative path from <root>. If not specified ' \
     'projects will be generated in <root>'
    default '.'
    flags :no_check_exist
  end
  
  attr :src, type: :path do
    help 'Source files. Evaluated once per project so this should be the union of all source files required for all target platforms.'
    flags :array
  end
  
  attr :targets do
    help 'Targets'
    flags :array, :required, :unordered
  end
  
end

##
#
define :workspace do
end
