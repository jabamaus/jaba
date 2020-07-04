## cpp
> 
> _Cross platform C++ project definition_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:3 |
> | _notes_ | Manages attribute definitions for 'cpp' type.  |
> 

<a id="arch"></a>
#### arch
> _Target architecture as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _default_ | nil |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:183 |
> | _notes_ | Query current architecture being processed. Use to define control flow to set config-specific atttributes.  |
>
<a id="arch_ref"></a>
#### arch_ref
> _Target architecture as an object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _referenced_type_ | :arch |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:189 |
>
<a id="archs"></a>
#### archs
> _Target architectures_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array |
> | _items_ | [:x86, :x86_64, :arm64] |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:63 |
>
> *Examples*
>```ruby
> archs [:x86, :x86_64]
>```
<a id="bindir"></a>
#### bindir
> _Output directory for executables_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ |  |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:233 |
>
<a id="buildroot"></a>
#### buildroot
> _Root directory for build artifacts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ | "build" |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:226 |
> | _notes_ | Specified as a relative path from [$(root)](#root).  |
>
<a id="cflags"></a>
#### cflags
> _Raw compiler command line switches_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:257 |
>
<a id="character_set"></a>
#### character_set
> _Character set_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _items_ | [:mbcs, :unicode, nil] |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:347 |
>
> *Examples*
>```ruby
> character_set :unicode
>```
<a id="config"></a>
#### config
> _Current target config as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _default_ | nil |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:210 |
> | _notes_ | Returns current config being processed. Use to define control flow to set config-specific atttributes.  |
>
<a id="configname"></a>
#### configname
> _Display name of config as seen in IDE_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:262 |
>
<a id="configs"></a>
#### configs
> _Build configurations_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array |
> | _default_ | nil |
> | _flags_ | :required, :no_sort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:70 |
>
> *Examples*
>```ruby
> configs [:Debug, :Release]
>```
<a id="debug"></a>
#### debug
> _Flags config as a debug config_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:269 |
> | _notes_ | Defaults to true if config id contains 'debug'.  |
>
<a id="defines"></a>
#### defines
> _Preprocessor defines_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:277 |
>
<a id="deps"></a>
#### deps
> _Project dependencies_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference array |
> | _referenced_type_ | :cpp |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:101 |
> | _notes_ | List of ids of other cpp definitions.  |
>
> *Examples*
>```ruby
> cpp :MyApp do
>   type :app
>   ...
>   deps [:MyLib]
> end
> 
> cpp :MyLib do
>   type :lib
>   ...
> end
>       
>```
<a id="exceptions"></a>
#### exceptions
> _Enables C++ exceptions_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _items_ | [true, false, :structured] |
> | _default_ | true |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:358 |
>
> *Examples*
>```ruby
> exceptions false # disable exceptions
>```
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
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:48 |
> | _notes_ | Seeded by [$(projname)](#projname). Required by Visual Studio project files.  |
>
<a id="host"></a>
#### host
> _Target host as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _default_ | nil |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:37 |
> | _notes_ | Query current target host.  |
>
> *Examples*
>```ruby
> case host
> when :vs2019
>   ...
> when :xcode
>   ...
> end
>       
>```
<a id="host_ref"></a>
#### host_ref
> _Target host as object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _referenced_type_ | :host |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:51 |
> | _notes_ | Use when access to host attributes is required.  |
>
<a id="hosts"></a>
#### hosts
> _Target hosts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array |
> | _items_ | [:vs2010, :vs2012, :vs2013, :vs2015, :vs2017, :vs2019, :xcode] |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:7 |
> | _notes_ | The following hosts are available as standard: vs2010, vs2012, vs2013, vs2015, vs2017, vs2019, xcode.  |
>
<a id="inc"></a>
#### inc
> _Include paths_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir array |
> | _default_ | nil |
> | _flags_ | :no_sort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:282 |
>
> *Examples*
>```ruby
> inc ['mylibrary/include']
> inc ['mylibrary/include'], :export # Export include path to dependents
>```
<a id="libdir"></a>
#### libdir
> _Output directory for libs_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ |  |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:241 |
>
<a id="nowarn"></a>
#### nowarn
> _Warnings to disable_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:290 |
> | _notes_ | Placed directly into projects as is, with no validation.  |
>
> *Examples*
>```ruby
> nowarn [4100, 4127, 4244] if visual_studio?
>```
<a id="objdir"></a>
#### objdir
> _Output directory for object files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ |  |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:249 |
>
<a id="platform"></a>
#### platform
> _Target platform as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _default_ | nil |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:79 |
> | _notes_ | Query current target platform.  |
>
> *Examples*
>```ruby
> case platform
> when :windows
>   ...
> when :macos
>   ...
> end
>       
>```
<a id="platform_ref"></a>
#### platform_ref
> _Target platform as an object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _referenced_type_ | :platform |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:93 |
> | _notes_ | Use when access to platform attributes is required.  |
>
<a id="platforms"></a>
#### platforms
> _Target platforms_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array |
> | _items_ | [:windows, :ios, :macos] |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:27 |
>
> *Examples*
>```ruby
> platforms [:windows]
> platforms [:macos, :ios]
>```
<a id="projdir"></a>
#### projdir
> _Directory in which projects will be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ | "." |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:122 |
> | _notes_ | Specified as an offset from [$(root)](#root). If not specified projects will be generated in [$(root)](#root). Path can also be absolute but explicitly specified absolute paths should be avoided in definitions where possible in order to not damage portability.  |
>
> *Examples*
>```ruby
> cpp :MyApp do
>   src ['**/*'] # Get all src in $(root), which defaults to directory of definition file
>   projdir 'projects' # Place generated projects in 'projects' directory
> end
>       
>```
<a id="projname"></a>
#### projname
> _Base name of project files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:137 |
> | _notes_ | Defaults to [$(id)](#id)[$(projsuffix)](#projsuffix).  |
>
<a id="projsuffix"></a>
#### projsuffix
> _Optional suffix to be applied to $(projname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:145 |
> | _notes_ | Has no effect if [$(projname)](#projname) is set explicitly.  |
>
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:14 |
> | _notes_ | Root of the project specified as an offset from the file that contains the project definition. All paths are specified relative to this. Project files will be generated here unless [$(projdir)](#projdir) is set. Path can also be absolute but explicitly specified absolute paths should be avoided in definitions where possible in order to not damage portability.  |
>
<a id="rtti"></a>
#### rtti
> _Enables runtime type information_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | true |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:366 |
>
> *Examples*
>```ruby
> rtti false # Disable rtti
>```
<a id="shell"></a>
#### shell
> _Shell commands to execute during build_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:219 |
> | _notes_ | Maps to build events in Visual Studio.  |
>
<a id="src"></a>
#### src
> _Source file specification_
> 
> | Property | Value  |
> |-|-|
> | _type_ | src_spec array |
> | _default_ | nil |
> | _flags_ | :required, :no_sort |
> | _options_ | :force, :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:150 |
>
> *Examples*
>```ruby
> src ['*']  # Add all src in $(root) whose extension is in $(src_ext)
> src ['src/**/*'] # Add all src in $(root)/src whose extension is in $(src_ext), recursively
> src ['main.c', 'io.c'] # Add src explicitly
> src ['jaba.jdl.rb']  # Explicitly add even though not in $(src_ext)
> src ['does_not_exist.cpp'], :force  # Force addition of file not on disk
>```
<a id="src_ext"></a>
#### src_ext
> _File extensions used when matching src files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array |
> | _default_ |  |
> | _flags_ | :no_sort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:166 |
> | _notes_ | Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes..  |
>
<a id="targetext"></a>
#### targetext
> _Extension to apply to $(targetname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:315 |
> | _notes_ | Defaults to standard extension for [$(type)](#type) of project for target [$(platform)](#platform).  |
>
<a id="targetname"></a>
#### targetname
> _Base name of output file without extension_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:297 |
> | _notes_ | Defaults to [$(targetprefix)](#targetprefix)[$(projname)](#projname)[$(targetsuffix)](#targetsuffix).  |
>
<a id="targetprefix"></a>
#### targetprefix
> _Prefix to apply to $(targetname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:305 |
> | _notes_ | Has no effect if [$(targetname)](#targetname) specified.  |
>
<a id="targetsuffix"></a>
#### targetsuffix
> _Suffix to apply to $(targetname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:310 |
> | _notes_ | Has no effect if [$(targetname)](#targetname) specified.  |
>
<a id="toolset"></a>
#### toolset
> _Toolset version to use_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:372 |
> | _notes_ | Defaults to host's default toolset.  |
>
<a id="type"></a>
#### type
> _Project type_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _items_ | [:app, :console, :lib, :dll] |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:202 |
>
<a id="vcglobal"></a>
#### vcglobal
> _Address Globals property group in a vcxproj directly_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s hash |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:56 |
>
<a id="vcproperty"></a>
#### vcproperty
> _Address per-configuration sections of a vcxproj directly_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s hash |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:77 |
>
<a id="warnerror"></a>
#### warnerror
> _Enable warnings as errors_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:340 |
>
> *Examples*
>```ruby
> warnerror true
>```
<a id="winsdkver"></a>
#### winsdkver
> _Windows SDK version_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _items_ | ["10.0.16299.0", "10.0.17134.0", "10.0.17763.0", "10.0.18362.0", nil] |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:62 |
>
