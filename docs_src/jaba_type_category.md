[home](index.html)
## category
> 
> _Project category type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/category.jaba:1 |
> | _notes_ | Manages attribute definitions for 'category' type.  |
> | _depends on_ |  |
> 

<a id="guid"></a>
#### guid
> _Globally unique id (GUID)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | uuid |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jaba:104 |
> | _notes_ | Seeded by [$(name)](#name). Required by Visual Studio .sln files.  |
>
<a id="name"></a>
#### name
> _Display name of category_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/category.jaba:5 |
> | _notes_ | Maps to name of solution folder in a Visual Studio solution.  |
>
<a id="parent"></a>
#### parent
> _Parent category_
> 
> | Property | Value  |
> |-|-|
> | _type_ | node_ref |
> | _node_type_ | :category |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/category.jaba:11 |
> | _notes_ | Use this to build a category hierarchy that can be used to classify projects in workspaces.  |
>
