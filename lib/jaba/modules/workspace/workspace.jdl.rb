define :workspace do

  help 'Represents a workspace that holds a set of projects'

  dependencies :cpp
  
  attr :root, type: :dir do
    title 'Root directory relative to which all other paths are specified'
    help 'Defaults to containing directory of definition source file'
    default '.'
  end

  attr_array :projects, type: :symbol_or_string do
    title 'Contained projects'
    help 'Specified by id (symbol or string), or by glob matches against <projroot>'
    flags :nosort # Matches will be sorted so no need to sort spec
  end

end
