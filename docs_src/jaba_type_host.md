## host
[home](index.html)
> 
> _Target host type_
> 
> | Property | Value  |
> |-|-|
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
> | _notes_ | Manages attribute definitions for 'host' type.  |
> | _depends on_ |  |
> 

<a id="cpp_project_classname"></a>
#### cpp_project_classname
> _Class name of host-specific Project subclass_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :string |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/cpp/cpp.jaba |
> | _notes_ | For example Vcxproj, Xcodeproj. Use when implementing a new project type..  |
>
<a id="cpp_src_ext"></a>
#### cpp_src_ext
> _Default src file extensions for C++ projects_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :string [] |
> | _default_ | [] |
> | _flags_ | :no_sort |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/cpp/cpp.jaba |
> | _notes_ | Any host-specific extensions specified are in addition to the Core C/C+ file types specified in [$(cpp#src_ext)](#cpp-src_ext).  |
>
<a id="cpp_supported_platforms"></a>
#### cpp_supported_platforms
> _Valid target platforms for this host_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  [] |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/cpp/cpp.jaba |
>
<a id="major_version"></a>
#### major_version
> _Host major version_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
<a id="ninja?"></a>
#### ninja?
> _Targeting ninja?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
<a id="toolset"></a>
#### toolset
> _Default toolset for host_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
<a id="version"></a>
#### version
> _Host version string_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
<a id="version_year"></a>
#### version_year
> _Host version year_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
<a id="visual_studio?"></a>
#### visual_studio?
> _Targeting Visual Studio?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
<a id="vs2010?"></a>
#### vs2010?
> _Returns true if current target host is vs2010_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
> *Examples*
>```ruby
> if vs2010?
>   ...
> end
> vcprop :VS2010Specific, 'value' if vs2010?
>```
<a id="vs2012?"></a>
#### vs2012?
> _Returns true if current target host is vs2012_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
> *Examples*
>```ruby
> if vs2012?
>   ...
> end
> vcprop :VS2012Specific, 'value' if vs2012?
>```
<a id="vs2013?"></a>
#### vs2013?
> _Returns true if current target host is vs2013_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
> *Examples*
>```ruby
> if vs2013?
>   ...
> end
> vcprop :VS2013Specific, 'value' if vs2013?
>```
<a id="vs2015?"></a>
#### vs2015?
> _Returns true if current target host is vs2015_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
> *Examples*
>```ruby
> if vs2015?
>   ...
> end
> vcprop :VS2015Specific, 'value' if vs2015?
>```
<a id="vs2017?"></a>
#### vs2017?
> _Returns true if current target host is vs2017_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
> *Examples*
>```ruby
> if vs2017?
>   ...
> end
> vcprop :VS2017Specific, 'value' if vs2017?
>```
<a id="vs2019?"></a>
#### vs2019?
> _Returns true if current target host is vs2019_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
> *Examples*
>```ruby
> if vs2019?
>   ...
> end
> vcprop :VS2019Specific, 'value' if vs2019?
>```
<a id="workspace_classname"></a>
#### workspace_classname
> _Class name of host-specific Workspace subclass_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/workspace/workspace.jaba |
> | _notes_ | For example Sln, XcodeWorkspace. Use when implementing a new workspace type..  |
>
<a id="xcode?"></a>
#### xcode?
> _Targeting Xcode?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | :bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _defined in_ | $(jaba_install)/modules/core/hosts.jaba |
>
