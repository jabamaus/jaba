## text
> 
> _Basic text file that is written to HDD_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/text/text.jaba:1 |
> | _notes_ | Manages attribute definitions for 'text' type.  |
> 

<a id="content"></a>
#### content
> _Content as a single multiline string_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jaba:10 |
> | _notes_ | Directly set content of file as a string..  |
>
<a id="eol"></a>
#### eol
> _End of line style_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _items_ | [:lf, :crlf, :native] |
> | _default_ | :native |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jaba:20 |
>
<a id="filename"></a>
#### filename
> _Path of the filename to be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | file |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jaba:5 |
>
<a id="line"></a>
#### line
> _Adds a line of content to file_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s array |
> | _default_ | nil |
> | _flags_ | :allow_dupes, :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jaba:15 |
>
