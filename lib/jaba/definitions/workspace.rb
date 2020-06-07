define :workspace do

  help 'Represents a workspace that holds a set of projects'

  attr_array :projects, type: :symbol_or_string do
    title 'Contained projects'
    help 'Specified by id (symbol or string), or by glob matches against <projroot>'
    flags :nosort # Matches will be sorted so no need to sort spec
  end

end
