shared :project do
  
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
    default { "#{_ID}#{namesuffix}" }
  end
  
  attr :namesuffix do
    help 'Optional suffix to be applied to project name. Used by <name> by default but will have no effect ' \
         'if <name> is set explicitly'
  end
  
  attr_array :src, type: :path do
  end
  
end
