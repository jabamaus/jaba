define :workspace do

  title 'Workspace of projects'

  dependencies :cpp
  
  attr :root, type: :dir do
    title 'Root directory relative to which all other paths are specified'
    note 'Defaults to containing directory of definition source file'
    default '.'
  end

  attr_array :projects, type: :symbol_or_string do
    title 'Contained projects'
    note 'Specified by id (symbol or string), or by glob matches against $(projroot)'
    flags :nosort # Matches will be sorted so no need to sort spec
  end

end
