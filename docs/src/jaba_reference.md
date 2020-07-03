# Jaba Definition Language Reference

- Attribute variants
  - single
  - array
  - hash
- Attribute types
  - bool
  - choice
  - dir
  - file
  - int
  - reference
  - src_spec
  - string
  - symbol
  - symbol_or_string
  - to_s
  - uuid
- Attribute flags
  - allow_dupes
  - expose
  - no_check_exist
  - no_sort
  - read_only
  - required
- Types
  - [arch](#arch-type)
    - [arm64?](#arch-arm64?)
    - [vsname](#arch-vsname)
    - [x86?](#arch-x86?)
    - [x86_64?](#arch-x86_64?)
  - [category](#category-type)
    - [guid](#category-guid)
    - [name](#category-name)
    - [parent](#category-parent)
  - [cpp](#cpp-type)
    - [arch](#cpp-arch)
    - [arch_ref](#cpp-arch_ref)
    - [archs](#cpp-archs)
    - [bindir](#cpp-bindir)
    - [buildroot](#cpp-buildroot)
    - [cflags](#cpp-cflags)
    - [character_set](#cpp-character_set)
    - [config](#cpp-config)
    - [configname](#cpp-configname)
    - [configs](#cpp-configs)
    - [debug](#cpp-debug)
    - [defines](#cpp-defines)
    - [deps](#cpp-deps)
    - [exceptions](#cpp-exceptions)
    - [guid](#cpp-guid)
    - [host](#cpp-host)
    - [host_ref](#cpp-host_ref)
    - [hosts](#cpp-hosts)
    - [inc](#cpp-inc)
    - [libdir](#cpp-libdir)
    - [nowarn](#cpp-nowarn)
    - [objdir](#cpp-objdir)
    - [platform](#cpp-platform)
    - [platform_ref](#cpp-platform_ref)
    - [platforms](#cpp-platforms)
    - [projdir](#cpp-projdir)
    - [projname](#cpp-projname)
    - [projsuffix](#cpp-projsuffix)
    - [root](#cpp-root)
    - [rtti](#cpp-rtti)
    - [shell](#cpp-shell)
    - [src](#cpp-src)
    - [src_ext](#cpp-src_ext)
    - [targetext](#cpp-targetext)
    - [targetname](#cpp-targetname)
    - [targetprefix](#cpp-targetprefix)
    - [targetsuffix](#cpp-targetsuffix)
    - [toolset](#cpp-toolset)
    - [type](#cpp-type)
    - [vcglobal](#cpp-vcglobal)
    - [vcproperty](#cpp-vcproperty)
    - [warnerror](#cpp-warnerror)
    - [winsdkver](#cpp-winsdkver)
  - [globals](#globals-type)
    - [vcfiletype](#globals-vcfiletype)
  - [host](#host-type)
    - [cpp_project_classname](#host-cpp_project_classname)
    - [cpp_src_ext](#host-cpp_src_ext)
    - [major_version](#host-major_version)
    - [toolset](#host-toolset)
    - [version](#host-version)
    - [version_year](#host-version_year)
    - [visual_studio?](#host-visual_studio?)
    - [vs2010?](#host-vs2010?)
    - [vs2012?](#host-vs2012?)
    - [vs2013?](#host-vs2013?)
    - [vs2015?](#host-vs2015?)
    - [vs2017?](#host-vs2017?)
    - [vs2019?](#host-vs2019?)
    - [workspace_classname](#host-workspace_classname)
    - [xcode?](#host-xcode?)
  - [platform](#platform-type)
    - [apple?](#platform-apple?)
    - [cpp_src_ext](#platform-cpp_src_ext)
    - [ios?](#platform-ios?)
    - [macos?](#platform-macos?)
    - [microsoft?](#platform-microsoft?)
    - [valid_archs](#platform-valid_archs)
    - [windows?](#platform-windows?)
  - [text](#text-type)
    - [content](#text-content)
    - [eol](#text-eol)
    - [filename](#text-filename)
    - [line](#text-line)
  - [workspace](#workspace-type)
    - [configs](#workspace-configs)
    - [name](#workspace-name)
    - [namesuffix](#workspace-namesuffix)
    - [primary](#workspace-primary)
    - [projects](#workspace-projects)
    - [root](#workspace-root)
    - [workspacedir](#workspace-workspacedir)

---

<a id="arch-type"></a>
## arch
> 
> _Target architecture type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/archs.jdl.rb:3 |
> | _notes_ | Manages attribute definitions for 'arch' type.  |
> 

<a id="arch-arm64?"></a>
#### arm64?
> _Returns true if current target architecture is arm64_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/archs.jdl.rb:8 |
>
> *Examples*
>```ruby
> if arm64?
>   ...
> end
>       
> src ['arch_arm64.cpp'] if arm64?
>```
<a id="arch-vsname"></a>
#### vsname
> _Name of target architecture (platform) as seen in Visual Studio IDE_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ | "" |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:28 |
>
<a id="arch-x86?"></a>
#### x86?
> _Returns true if current target architecture is x86_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/archs.jdl.rb:8 |
>
> *Examples*
>```ruby
> if x86?
>   ...
> end
>       
> src ['arch_x86.cpp'] if x86?
>```
<a id="arch-x86_64?"></a>
#### x86_64?
> _Returns true if current target architecture is x86_64_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/archs.jdl.rb:8 |
>
> *Examples*
>```ruby
> if x86_64?
>   ...
> end
>       
> src ['arch_x86_64.cpp'] if x86_64?
>```

---

<a id="category-type"></a>
## category
> 
> _Project category type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/category.jdl.rb:1 |
> | _notes_ | Manages attribute definitions for 'category' type.  |
> 

<a id="category-guid"></a>
#### guid
> _Globally unique id (GUID)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | uuid |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:86 |
> | _notes_ | Seeded by [$(name)](#name). Required by Visual Studio .sln files.  |
>
<a id="category-name"></a>
#### name
> _Display name of category_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/category.jdl.rb:5 |
> | _notes_ | Maps to name of solution folder in a Visual Studio solution.  |
>
<a id="category-parent"></a>
#### parent
> _Parent category_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _referenced_type_ | :category |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/category.jdl.rb:11 |
> | _notes_ | Use this to build a category hierarchy that can be used to classify projects in workspaces.  |
>

---

<a id="cpp-type"></a>
## cpp
> 
> _Cross platform C++ project definition_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:3 |
> | _notes_ | Manages attribute definitions for 'cpp' type.  |
> 

<a id="cpp-arch"></a>
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
<a id="cpp-arch_ref"></a>
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
<a id="cpp-archs"></a>
#### archs
> _Target architectures_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array |
> | _items_ | [:x86, :x86_64, :arm64] |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:63 |
>
> *Examples*
>```ruby
> archs [:x86, :x86_64]
>```
<a id="cpp-bindir"></a>
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
<a id="cpp-buildroot"></a>
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
<a id="cpp-cflags"></a>
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
<a id="cpp-character_set"></a>
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
<a id="cpp-config"></a>
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
<a id="cpp-configname"></a>
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
<a id="cpp-configs"></a>
#### configs
> _Build configurations_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array |
> | _flags_ | :required, :no_sort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:70 |
>
> *Examples*
>```ruby
> configs [:Debug, :Release]
>```
<a id="cpp-debug"></a>
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
<a id="cpp-defines"></a>
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
<a id="cpp-deps"></a>
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
<a id="cpp-exceptions"></a>
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
<a id="cpp-guid"></a>
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
<a id="cpp-host"></a>
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
<a id="cpp-host_ref"></a>
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
<a id="cpp-hosts"></a>
#### hosts
> _Target hosts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array |
> | _items_ | [:vs2010, :vs2012, :vs2013, :vs2015, :vs2017, :vs2019, :xcode] |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:7 |
> | _notes_ | The following hosts are available as standard: vs2010, vs2012, vs2013, vs2015, vs2017, vs2019, xcode.  |
>
<a id="cpp-inc"></a>
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
<a id="cpp-libdir"></a>
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
<a id="cpp-nowarn"></a>
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
<a id="cpp-objdir"></a>
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
<a id="cpp-platform"></a>
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
<a id="cpp-platform_ref"></a>
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
<a id="cpp-platforms"></a>
#### platforms
> _Target platforms_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array |
> | _items_ | [:windows, :ios, :macos] |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:27 |
>
> *Examples*
>```ruby
> platforms [:windows]
> platforms [:macos, :ios]
>```
<a id="cpp-projdir"></a>
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
<a id="cpp-projname"></a>
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
<a id="cpp-projsuffix"></a>
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
<a id="cpp-root"></a>
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
<a id="cpp-rtti"></a>
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
<a id="cpp-shell"></a>
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
<a id="cpp-src"></a>
#### src
> _Source file specification_
> 
> | Property | Value  |
> |-|-|
> | _type_ | src_spec array |
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
<a id="cpp-src_ext"></a>
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
<a id="cpp-targetext"></a>
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
<a id="cpp-targetname"></a>
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
<a id="cpp-targetprefix"></a>
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
<a id="cpp-targetsuffix"></a>
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
<a id="cpp-toolset"></a>
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
<a id="cpp-type"></a>
#### type
> _Project type_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _items_ | [:app, :console, :lib, :dll] |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:202 |
>
<a id="cpp-vcglobal"></a>
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
<a id="cpp-vcproperty"></a>
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
<a id="cpp-warnerror"></a>
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
<a id="cpp-winsdkver"></a>
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

---

<a id="globals-type"></a>
## globals
> 
> _Global attribute definitions_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/globals.jdl.rb:1 |
> | _notes_ | Manages attribute definitions for 'globals' type.  |
> 

<a id="globals-vcfiletype"></a>
#### vcfiletype
> _Visual C++ file types_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol hash |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:2 |
>

---

<a id="host-type"></a>
## host
> 
> _Target host type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:4 |
> | _notes_ | Manages attribute definitions for 'host' type.  |
> 

<a id="host-cpp_project_classname"></a>
#### cpp_project_classname
> _Class name of host-specific Project subclass_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:383 |
> | _notes_ | For example Vcxproj, Xcodeproj. Use when implementing a new project type..  |
>
<a id="host-cpp_src_ext"></a>
#### cpp_src_ext
> _Default src file extensions for C++ projects_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array |
> | _default_ | [] |
> | _flags_ | :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:389 |
> | _notes_ | Any host-specific extensions specified are in addition to the Core C/C+ file types specified in [$(cpp#src_ext)](#cpp-src_ext).  |
>
<a id="host-major_version"></a>
#### major_version
> _Host major version_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:16 |
>
<a id="host-toolset"></a>
#### toolset
> _Default toolset for host_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:25 |
>
<a id="host-version"></a>
#### version
> _Host version string_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:19 |
>
<a id="host-version_year"></a>
#### version_year
> _Host version year_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:22 |
>
<a id="host-visual_studio?"></a>
#### visual_studio?
> _Targeting Visual Studio?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:8 |
>
<a id="host-vs2010?"></a>
#### vs2010?
> _Returns true if current target host is vs2010_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:31 |
>
> *Examples*
>```ruby
> if vs2010?
>   ...
> end
>       
> vcproperty :VS2010Specific, 'value' if vs2010?
>```
<a id="host-vs2012?"></a>
#### vs2012?
> _Returns true if current target host is vs2012_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:31 |
>
> *Examples*
>```ruby
> if vs2012?
>   ...
> end
>       
> vcproperty :VS2012Specific, 'value' if vs2012?
>```
<a id="host-vs2013?"></a>
#### vs2013?
> _Returns true if current target host is vs2013_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:31 |
>
> *Examples*
>```ruby
> if vs2013?
>   ...
> end
>       
> vcproperty :VS2013Specific, 'value' if vs2013?
>```
<a id="host-vs2015?"></a>
#### vs2015?
> _Returns true if current target host is vs2015_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:31 |
>
> *Examples*
>```ruby
> if vs2015?
>   ...
> end
>       
> vcproperty :VS2015Specific, 'value' if vs2015?
>```
<a id="host-vs2017?"></a>
#### vs2017?
> _Returns true if current target host is vs2017_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:31 |
>
> *Examples*
>```ruby
> if vs2017?
>   ...
> end
>       
> vcproperty :VS2017Specific, 'value' if vs2017?
>```
<a id="host-vs2019?"></a>
#### vs2019?
> _Returns true if current target host is vs2019_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:31 |
>
> *Examples*
>```ruby
> if vs2019?
>   ...
> end
>       
> vcproperty :VS2019Specific, 'value' if vs2019?
>```
<a id="host-workspace_classname"></a>
#### workspace_classname
> _Class name of host-specific Workspace subclass_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:52 |
> | _notes_ | For example Sln, XcodeWorkspace. Use when implementing a new workspace type..  |
>
<a id="host-xcode?"></a>
#### xcode?
> _Targeting Xcode?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:12 |
>

---

<a id="platform-type"></a>
## platform
> 
> _Target platform type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:4 |
> | _notes_ | Manages attribute definitions for 'platform' type. Manages attribute definitions required by platforms.  |
> 

<a id="platform-apple?"></a>
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
<a id="platform-cpp_src_ext"></a>
#### cpp_src_ext
> _Default src file extensions for C++ projects_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array |
> | _default_ | [] |
> | _flags_ | :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:398 |
> | _notes_ | Any platform-specific extensions specified are in addition to the Core C/C+ file types specified in [$(cpp#src_ext)](#cpp-src_ext).  |
>
<a id="platform-ios?"></a>
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
<a id="platform-macos?"></a>
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
<a id="platform-microsoft?"></a>
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
<a id="platform-valid_archs"></a>
#### valid_archs
> _List of architectures supported by this platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array |
> | _items_ | [:x86, :x86_64, :arm64] |
> | _flags_ | :required, :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:34 |
>
<a id="platform-windows?"></a>
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

---

<a id="text-type"></a>
## text
> 
> _Basic text file that is written to HDD_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:1 |
> | _notes_ | Manages attribute definitions for 'text' type.  |
> 

<a id="text-content"></a>
#### content
> _Content as a single multiline string_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:10 |
> | _notes_ | Directly set content of file as a string..  |
>
<a id="text-eol"></a>
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
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:20 |
>
<a id="text-filename"></a>
#### filename
> _Path of the filename to be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | file |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:5 |
>
<a id="text-line"></a>
#### line
> _Adds a line of content to file_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s array |
> | _default_ | nil |
> | _flags_ | :allow_dupes, :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:15 |
>

---

<a id="workspace-type"></a>
## workspace
> 
> _Workspace of projects_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:1 |
> | _notes_ | Manages attribute definitions for 'workspace' type.  |
> 

<a id="workspace-configs"></a>
#### configs
> _Solution configurations_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array |
> | _default_ | nil |
> | _flags_ | :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:44 |
>
<a id="workspace-name"></a>
#### name
> _Base name of workspace files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:27 |
>
<a id="workspace-namesuffix"></a>
#### namesuffix
> _Optional suffix to be applied to $(name)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:34 |
> | _notes_ | Has no effect if [$(name)](#name) is set explicitly.  |
>
<a id="workspace-primary"></a>
#### primary
> _Primary project_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:39 |
>
<a id="workspace-projects"></a>
#### projects
> _Contained projects_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array |
> | _flags_ | :required, :no_sort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:19 |
> | _notes_ | Specified by id (symbol or string), or by glob matches against [$(projdir)](#projdir).  |
>
<a id="workspace-root"></a>
#### root
> _Root directory relative to which all other paths are specified_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ | "." |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:7 |
> | _notes_ | Defaults to containing directory of definition source file.  |
>
<a id="workspace-workspacedir"></a>
#### workspacedir
> _Directory in which workspaces will be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _default_ | "." |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:13 |
>

