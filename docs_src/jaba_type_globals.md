[home](index.html)
## globals
> 
> _Global attribute definitions_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/globals.jaba:1 |
> | _notes_ | Manages attribute definitions for 'globals' type.  |
> | _depends on_ | [host](jaba_type_host.html) |
> 

<a id="cpp_hosts"></a>
#### cpp_hosts
> _Target hosts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | node_ref array |
> | _node_type_ | :host |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:415 |
>
<a id="dump_input"></a>
#### dump_input
> _Controls generation of $(jaba_input_file)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/globals.jaba:21 |
>
<a id="dump_output"></a>
#### dump_output
> _Controls generation of $(jaba_output_file)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | true |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/globals.jaba:33 |
>
<a id="jaba_input_file"></a>
#### jaba_input_file
> _Name/path of file to contain a raw dump of all the input data to Jaba_
> 
> | Property | Value  |
> |-|-|
> | _type_ | file |
> | _default_ | ".jaba/jaba.input.json" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/globals.jaba:13 |
> | _notes_ | Mostly useful for debugging and testing but could be useful as a second way of tracking definition changes in source control. The file is written before any file generation occurs, and can be considered a specification of the final data.  |
>
<a id="jaba_output_file"></a>
#### jaba_output_file
> _Name/path of file to contain Jaba output in json format_
> 
> | Property | Value  |
> |-|-|
> | _type_ | file |
> | _default_ | ".jaba/jaba.output.json" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/globals.jaba:25 |
> | _notes_ | Jaba output can be later used by another process (eg the build process) to do things like looking up paths by id rather than embedding them in code, iterating over all defined unit tests and invoking them, etc..  |
>
<a id="src_root"></a>
#### src_root
> _Root of source tree_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ | "." |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/globals.jaba:5 |
> | _notes_ | Tells Jaba where to start looking for .jaba files to execute. Defaults to the directory Jaba was invoked in if not specified on the command line. Often coincident with the root of a source tree, but not always as jaba files can exist outside a src tree if desired..  |
>
<a id="vcfiletype"></a>
#### vcfiletype
> _Visual C++ file types_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol hash |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jaba:2 |
>
