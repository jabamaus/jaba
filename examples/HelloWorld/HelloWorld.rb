##
# Some thoughts...
#
define :test_project do
  
  dependencies [:platform, :host]

  node do
    attr :root, type: :dir do
      help 'Root of the project specified as a relative path to the file that contains the project definition. ' \
           'All paths are specified relative to this. Project files will be generated here unless the genroot attribute is used.'
      default '.'
    end

    attr :platforms, type: :reference do
      flags :array, :unordered, :required
    end
  end
  
  node do
    multiplicity :platforms => :platform
    
    attr :platform do
    end

    attr :hosts, type: :reference do
      flags :array, :unordered, :required
    end
  end
  
  node do
    multiplicity :hosts => :host
    
    attr :host do
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
  
  node do
    multiplicity :targets
  end
   
end

build_use_case do

  setup do
    file "AppRoot/main.cpp"
  end
  
  jaba do
    project :myApp do
      root 'AppRoot'
    end
  end
  
  verify do
  end
  
end