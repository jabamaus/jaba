## workspace
> 
> _Workspace of projects_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/workspace/workspace.jaba:1 |
> | _notes_ | Manages attribute definitions for 'workspace' type.  |
> | _depends on_ | cpp |
> 

<a id="name"></a>
#### name
> _Base name of workspace files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jaba:30 |
>
<a id="namesuffix"></a>
#### namesuffix
> _Optional suffix to be applied to $(name)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jaba:37 |
> | _notes_ | Has no effect if [$(name)](#name) is set explicitly.  |
>
<a id="primary"></a>
#### primary
> _Primary project_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jaba:42 |
>
<a id="projects"></a>
#### projects
> _Contained projects_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array |
> | _default_ | nil |
> | _flags_ | :required, :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jaba:21 |
> | _notes_ | Specified by id (symbol or string), or by glob matches against project [$(root)](#root). Dependencies will be automatically pulled in..  |
>
> *Examples*
>```ruby
> 
> 
>```
<a id="root"></a>
#### root
> _Root directory relative to which all other paths are specified_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ | "." |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jaba:7 |
> | _notes_ | Defaults to containing directory of definition source file.  |
>
<a id="workspacedir"></a>
#### workspacedir
> _Directory in which workspaces will be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ | "projects" |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jaba:14 |
>
