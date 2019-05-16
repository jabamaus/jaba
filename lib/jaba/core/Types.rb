# TODO: add help string to flags
attr_flag :array
attr_flag :allow_dupes
attr_flag :no_check_exist
attr_flag :per_type
attr_flag :per_sku
attr_flag :per_target
attr_flag :read_only
attr_flag :required
attr_flag :unordered

# TODO: think about compatibility of flags to attribute types, eg :no_make_rel_to_genroot only applies to :path, :file and :dir attrs

##
#
attr_type :bool do
  default false
  supports_sort false
  supports_uniq false
  
  validate_value do |value|
    if !value.boolean?
      raise ':bool attributes only accept [true|false]'
    end
  end
end

##
#
attr_type :choice do
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
define :sku do
  attr :platform do
  end
  
  attr :host do
  end
end

##
# Define skus for VisualStudio.
#
[:win32, :x64].each do |p|
  [2015, 2017, 2019].each do |vs|
    host = "vs#{vs}"
    sku "#{p}_#{host}".to_sym do
      platform p
      host host
    end
  end
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
  
  attr :parent do
    help 'Makes this category a child of the specified category.'
    type :reference
  end
end

##
#
define :text do
  
  attr :filename do
    help 'Path to the filename to be generated'
    type :file
    flags :required
  end
  
  attr :content do
    help 'Directly set content of file as a string'
  end
  
  attr :line do
    help 'Set content of file line by line'
    flags :array, :allow_dupes, :unordered
  end
  
  attr :eol do
    help 'Newline style'
    type :choice
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
  evaluate :per_type, :per_sku, :per_target
  
  attr :skus do
    help 'skus'
    type :reference
    flags :per_type, :array, :unordered, :required
  end
  
  attr :root do
    help 'Root of the project specified as a relative path to the file that contains the project definition. ' \
         'All paths are specified relative to this. Project files will be generated here unless the genroot attribute is used.'
    type :dir
    default '.'
    flags :per_type
  end
  
  attr :genroot do
    help 'Directory in which projects will be generated. Specified as a relative path from <root>. If not specified ' \
     'projects will be generated in <root>'
    type :dir
    default '.'
    flags :per_sku, :no_check_exist
  end
  
  attr :src do
    help 'Source files. Evaluated once per project so this should be the union of all source files required for all target platforms.'
    type :path
    flags :per_sku, :array
  end
  
  attr :targets do
    help 'Targets'
    flags :per_sku, :array, :required, :unordered
  end
  
end

##
#
define :workspace do
  evaluate :per_type, :per_sku
end
