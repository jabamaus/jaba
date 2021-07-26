## arch
[home](index.html)
> 
> _Target architecture type_
> 
> | Property | Value  |
> |-|-|
> | _defined in_ | $(jaba_install)/modules/core/archs.jaba |
> | _notes_ | Manages attribute definitions for 'arch' type.  |
> | _depends on_ |  |
> 

<a id="arm64?"></a>
#### arm64?
> _Returns true if current target architecture is arm64_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/archs.jaba |
>
> *Examples*
>```ruby
> if arm64?
>   ...
> end
> src ['arch_arm64.cpp'] if arm64?
>```
<a id="vsname"></a>
#### vsname
> _Name of target architecture (platform) as seen in Visual Studio IDE_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :string |
> | _default_ | "" |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jaba |
>
<a id="x86?"></a>
#### x86?
> _Returns true if current target architecture is x86_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/archs.jaba |
>
> *Examples*
>```ruby
> if x86?
>   ...
> end
> src ['arch_x86.cpp'] if x86?
>```
<a id="x86_64?"></a>
#### x86_64?
> _Returns true if current target architecture is x86_64_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/archs.jaba |
>
> *Examples*
>```ruby
> if x86_64?
>   ...
> end
> src ['arch_x86_64.cpp'] if x86_64?
>```
