## platform
> 
> _Target platform type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:4 |
> | _notes_ | Manages attribute definitions for 'platform' type. Manages attribute definitions required by platforms.  |
> 

<a id="apple?"></a>
#### apple?
> _Returns true if current target platform is an Apple platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:27 |
> | _notes_ | Use only if attribute being set works across all current and future apple platforms. As such probably rarely used..  |
>
<a id="cpp_src_ext"></a>
#### cpp_src_ext
> _Default src file extensions for C++ projects_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array |
> | _default_ | [] |
> | _flags_ | :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:370 |
> | _notes_ | Any platform-specific extensions specified are in addition to the Core C/C+ file types specified in [$(cpp#src_ext)](#cpp-src_ext).  |
>
<a id="ios?"></a>
#### ios?
> _Returns true if current target platform is ios_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:10 |
>
> *Examples*
>```ruby
> if ios?
>   ...
> end
>       
> src ['imp_ios.cpp'] if ios?
>```
<a id="macos?"></a>
#### macos?
> _Returns true if current target platform is macos_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:10 |
>
> *Examples*
>```ruby
> if macos?
>   ...
> end
>       
> src ['imp_macos.cpp'] if macos?
>```
<a id="microsoft?"></a>
#### microsoft?
> _Returns true if current target platform is a Microsoft platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:22 |
>
<a id="valid_archs"></a>
#### valid_archs
> _List of architectures supported by this platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array |
> | _items_ | [:x86, :x86_64, :arm64] |
> | _default_ | nil |
> | _flags_ | :required, :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:34 |
>
<a id="windows?"></a>
#### windows?
> _Returns true if current target platform is windows_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:10 |
>
> *Examples*
>```ruby
> if windows?
>   ...
> end
>       
> src ['imp_windows.cpp'] if windows?
>```
