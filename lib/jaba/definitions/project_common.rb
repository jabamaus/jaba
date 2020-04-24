shared :project_common do
  
  attr :root, type: :dir do
    help 'Root of the project specified as a relative path to the file that contains the project definition. ' \
         'All paths are specified relative to this. Project files will be generated here unless <projroot> is set.'
    default '.'
  end

  attr :projroot, type: :dir do
    help 'Directory in which projects will be generated. Specified as a relative path from <root>. If not specified ' \
     'projects will be generated in <root>'
    default '.'
    flags :no_check_exist # May get created during generation
  end
  
  attr :name do
    help 'Seeds the name of the project. Defaults to the definition id if not set.'
    default { _ID }
  end
  
  attr :projname do
    help 'Seeds file basename of project files. Defaults to <name><projsuffix>.'
    default { "#{name}#{projname_suffix}" }
  end

  attr :projname_suffix do
    help 'Optional suffix to be applied to <projname>. Has no effect if <projname> is set explicitly.'
  end

  attr_array :src, type: :path do
  end
  
end
