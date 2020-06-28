define :text do
  
  title 'Basic text file that is written to HDD'

  attr :filename, type: :file do
    title 'Path of the filename to be generated'
    flags :required
  end
  
  attr :content do
    title 'Content as a single multiline string'
    note 'Directly set content of file as a string.'
  end
  
  attr_array :line do
    title 'Adds a line of content to file'
    flags :allow_dupes, :nosort
  end
  
  attr :eol, type: :choice do
    title 'End of line style'
    items [:lf, :crlf, :native]
    default :native
  end
  
end
