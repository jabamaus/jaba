# frozen_string_literal: true

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
  
  attr_array :line do
    help 'Set content of file line by line'
    flags :allow_dupes, :unordered
  end
  
  attr :eol, type: :choice do
    help 'Newline style'
    items [:lf, :crlf, :native]
    default :native
  end
  
end
