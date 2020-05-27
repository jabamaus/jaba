define :text do
  
  help 'Represents a simple text file that is written to HDD. See generators/text_generator.rb'

  attr :filename, type: :file do
    help 'Path to the filename to be generated'
    flags :required
  end
  
  attr :content do
    help 'Directly set content of file as a string. Takes precedence over line attribute, which will be ignored'
  end
  
  attr_array :line do
    help 'Adds a line of content to file'
    flags :allow_dupes, :nosort
  end
  
  attr :eol, type: :choice do
    help 'End of line style'
    items [:lf, :crlf, :native]
    default :native
  end
  
end
