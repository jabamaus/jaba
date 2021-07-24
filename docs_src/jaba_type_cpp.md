[home](index.html)
## cpp
> 
> _Cross platform C++ project definition_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:3 |
> | _notes_ | Manages attribute definitions for 'cpp' type.  |
> | _depends on_ | [host](jaba_type_host.html), [platform](jaba_type_platform.html), [arch](jaba_type_arch.html), [buildtool](jaba_type_buildtool.html) |
> 

<a id="arch"></a>
#### arch
> _Target architecture as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _default_ |  |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:161 |
> | _notes_ | Query current architecture being processed. Use to define control flow to set config-specific atttributes.  |
>
<a id="arch_ref"></a>
#### arch_ref
> _Target architecture as an object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | node_ref |
> | _node_type_ | :arch |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:167 |
>
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:212 |
>
<a id="build_root"></a>
#### build_root
> _Root directory for build artifacts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ | "build" |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:204 |
> | _notes_ | Specified as a relative path from main build root.  |
>
<a id="buildtool"></a>
#### buildtool
> _Custom build tool_
> 
> | Property | Value  |
> |-|-|
> | _type_ | node hash |
> | _node_type_ | :buildtool |
> | _default_ |  |
> | _flags_ | :delay_evaluation |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:189 |
>
<a id="cflags"></a>
#### cflags
> _Raw compiler command line switches_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:251 |
>
<a id="character_set"></a>
#### character_set
> _Character set_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _items_ | [:mbcs, :unicode, nil] |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:350 |
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
> | _default_ |  |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:182 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:256 |
>
<a id="configs"></a>
#### configs
> _Build configurations_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array |
> | _default_ |  |
> | _flags_ | :required, :no_sort |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:68 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:263 |
> | _notes_ | Defaults to true if config id contains 'debug'.  |
>
<a id="define"></a>
#### define
> _Preprocessor defines_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:271 |
>
<a id="deps"></a>
#### deps
> _Project dependencies_
> 
> | Property | Value  |
> |-|-|
> | _type_ | node_ref array |
> | _node_type_ | :cpp |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:75 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:361 |
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
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jaba:49 |
> | _notes_ | Seeded by [$(projname)](#projname). Required by Visual Studio project files.  |
>
<a id="host"></a>
#### host
> _Target host as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _default_ |  |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:26 |
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
>```
<a id="host_ref"></a>
#### host_ref
> _Target host as object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | node_ref |
> | _node_type_ | :host |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:40 |
> | _notes_ | Use when access to host attributes is required.  |
>
<a id="importlib"></a>
#### importlib
> _Name of import lib for use will dlls_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:285 |
> | _notes_ | Defaults to [$(projname)](#projname)[$(targetsuffix)](#targetsuffix).lib.  |
>
<a id="inc"></a>
#### inc
> _Include paths_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir array |
> | _default_ |  |
> | _flags_ | :no_sort |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:276 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:221 |
>
<a id="libs"></a>
#### libs
> _Paths to required non-system libs_
> 
> | Property | Value  |
> |-|-|
> | _type_ | file array |
> | _default_ |  |
> | _flags_ | :no_sort, :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:239 |
>
<a id="nowarn"></a>
#### nowarn
> _Warnings to disable_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:293 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:230 |
>
<a id="platform"></a>
#### platform
> _Target platform as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _default_ |  |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:46 |
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
>```
<a id="platform_ref"></a>
#### platform_ref
> _Target platform as an object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | node_ref |
> | _node_type_ | :platform |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:60 |
> | _notes_ | Use when access to platform attributes is required.  |
>
<a id="platforms"></a>
#### platforms
> _Target platforms_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:7 |
>
<a id="projdir"></a>
#### projdir
> _Directory in which projects will be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ | "projects" |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:96 |
> | _notes_ | Specified as an offset from [$(root)](#root). If not specified projects will be generated in [$(root)](#root). Path can also be absolute but explicitly specified absolute paths should be avoided in definitions where possible in order to not damage portability.  |
>
> *Examples*
>```ruby
> cpp :MyApp do
>   src ['**/*'] # Get all src in $(root), which defaults to directory of definition file
>   projdir 'projects' # Place generated projects in 'projects' directory
> end
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:112 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:120 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:14 |
> | _notes_ | Root of the project specified as an offset from the .jaba file that contains the project definition. All paths are specified relative to this. Project files will be generated here unless [$(projdir)](#projdir) is set. Path can also be absolute but explicitly specified absolute paths should be avoided in definitions where possible in order to not damage portability.  |
>
<a id="rtti"></a>
#### rtti
> _Enables runtime type information_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:369 |
>
> *Examples*
>```ruby
> rtti true
>```
<a id="shell"></a>
#### shell
> _Shell commands to execute during build_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:197 |
> | _notes_ | Maps to build events in Visual Studio.  |
>
<a id="src"></a>
#### src
> _Source file specification_
> 
> | Property | Value  |
> |-|-|
> | _type_ | src_spec array |
> | _default_ |  |
> | _flags_ | :required, :no_sort |
> | _options_ | :force, :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:125 |
>
> *Examples*
>```ruby
> src ['*']  # Add all src in $(root) whose extension is in $(src_ext)
> src ['src/**/*'] # Add all src in $(root)/src whose extension is in $(src_ext), recursively
> src ['main.c', 'io.c'] # Add src explicitly
> src ['build.jaba']  # Explicitly add even though not in $(src_ext)
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
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:142 |
> | _notes_ | Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes..  |
>
<a id="syslibs"></a>
#### syslibs
> _System libs_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array |
> | _default_ |  |
> | _flags_ | :no_sort |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:245 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:318 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:300 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:308 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:313 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:374 |
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
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:174 |
>
<a id="vcfprop"></a>
#### vcfprop
> _Add per-configuration per-file property_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s hash |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jaba:91 |
>
<a id="vcglobal"></a>
#### vcglobal
> _Address Globals property group in a vcxproj directly_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s hash |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jaba:57 |
>
<a id="vcprop"></a>
#### vcprop
> _Address per-configuration sections of a vcxproj directly_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s hash |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export, :export_only |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jaba:80 |
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
> | _src_ | $(jaba_install)/modules/cpp/cpp.jaba:343 |
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
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jaba:63 |
>
> *Examples*
>```ruby
> winsdkver '10.0.18362.0'
> # wrapper for
> vcglobal :WindowsTargetPlatformVersion, winsdkver
>```
