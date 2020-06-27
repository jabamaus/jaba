# Jaba Reference

- Attribute types
  - string
  - symbol
  - symbol_or_string
  - bool
  - choice
  - file
  - dir
  - src_spec
  - uuid
  - reference
- Attribute flags
  - required
  - read_only
  - expose
  - allow_dupes
  - nosort
  - no_check_exist
- Types
  - arch
    - arm64?
    - vsname
    - x86?
    - x86_64?
  - category
    - guid
    - name
    - parent
  - cpp
    - arch
    - arch_ref
    - archs
    - bindir
    - build_action
    - buildroot
    - cflags
    - character_set
    - config
    - configname
    - configs
    - debug
    - defines
    - deps
    - exceptions
    - guid
    - host
    - host_ref
    - hosts
    - inc
    - libdir
    - nowarn
    - objdir
    - platform
    - platform_ref
    - platforms
    - projname
    - projroot
    - projsuffix
    - root
    - rtti
    - src
    - src_ext
    - targetext
    - targetname
    - targetprefix
    - targetsuffix
    - toolset
    - type
    - vcglobal
    - vcproperty
    - warnerror
    - winsdkver
  - globals
    - vcfiletype
  - host
    - cpp_project_classname
    - major_version
    - toolset
    - version
    - version_year
    - visual_studio?
    - vs2010?
    - vs2012?
    - vs2013?
    - vs2015?
    - vs2017?
    - vs2019?
    - xcode?
  - platform
    - apple?
    - ios?
    - macos?
    - microsoft?
    - valid_archs
    - windows?
  - text
    - content
    - eol
    - filename
    - line
  - workspace
    - projects
    - root

---

## arch
> 
> _Target architecture_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/archs.jdl.rb:3 |
> | _notes_ |  |
> 

#### arm64?

> _Returns true if current architecture is arm64_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/archs.jdl.rb:8 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> if arm64?
>   ...
> end
>       
> src ['arch_arm64.cpp'] if arm64?
>```
#### vsname

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_visual_studio.jdl.rb:26 |
> | _notes_ | Name of target architecture (platform) as seen in Visual Studio IDE. |
#### x86?

> _Returns true if current architecture is x86_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/archs.jdl.rb:8 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> if x86?
>   ...
> end
>       
> src ['arch_x86.cpp'] if x86?
>```
#### x86_64?

> _Returns true if current architecture is x86_64_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/archs.jdl.rb:8 |
> | _notes_ |  |
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

## category
> 
> _Project category_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/category.jdl.rb:1 |
> | _notes_ |  |
> 

#### guid

> _Globally unique id (GUID)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | uuid |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_visual_studio.jdl.rb:84 |
> | _notes_ | Seeded by <name>. Required by Visual Studio .sln files. |
#### name

> _Display name of category_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/category.jdl.rb:5 |
> | _notes_ | Maps to name of solution folder in a Visual Studio solution. |
#### parent

> _Parent category_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/category.jdl.rb:11 |
> | _notes_ | Use this to build a category hierarchy that can be used to classify projects in workspaces. |

---

## cpp
> 
> _Cross platform C++ project definition_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:3 |
> | _notes_ |  |
> 

#### arch

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:166 |
> | _notes_ | Returns current arch being processed. Use to define control flow to set config-specific atttributes. |
#### arch_ref

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:171 |
> | _notes_ |  |
#### archs

> _Target architectures_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:61 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> archs [:x86, :x86_64]
>```
#### bindir

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:211 |
> | _notes_ |  |
#### build_action

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:197 |
> | _notes_ | Build action, eg a prebuild step. |
#### buildroot

> _Root directory for build artifacts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | build |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:204 |
> | _notes_ | Specified as a relative path from $(root). |
#### cflags

> _Raw compiler command line switches_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:232 |
> | _notes_ |  |
#### character_set

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:321 |
> | _notes_ | Character set. Defaults to :unicode. |
>
> *Examples*
>```ruby
> character_set :unicode
>```
#### config

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:190 |
> | _notes_ | Returns current config being processed. Use to define control flow to set config-specific atttributes. |
#### configname

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:237 |
> | _notes_ | Display name of config in Visual Studio. Defaults to $(config). |
#### configs

> _Build configurations_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :required,:nosort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:68 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> configs [:Debug, :Release]
>```
#### debug

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:244 |
> | _notes_ | Flags config as a debug build. Defaults to true if config id contains 'debug'. |
#### defines

> _Preprocessor defines_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:251 |
> | _notes_ |  |
#### deps

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:99 |
> | _notes_ | Specify project dependencies. List of ids of other cpp definitions. |
#### exceptions

> _Enables C++ exceptions_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ | true |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:332 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> exceptions false # disable exceptions
>```
#### guid

> _Globally unique id (GUID)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | uuid |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_visual_studio.jdl.rb:46 |
> | _notes_ | Seeded by <projname>. Required by Visual Studio project files. |
#### host

> _Target host_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:35 |
> | _notes_ | Use for querying the current target host. |
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
#### host_ref

> _Target host as object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:49 |
> | _notes_ | Use when access to host attributes is required. |
#### hosts

> _Target hosts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:7 |
> | _notes_ | The following hosts are available as standard: vs2010, vs2012, vs2013, vs2015, vs2017, vs2019, xcode. |
#### inc

> _Include paths_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :nosort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:256 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> inc ['mylibrary/include']
> inc ['mylibrary/include'], :export # Export include path to dependents
>```
#### libdir

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:218 |
> | _notes_ |  |
#### nowarn

> _Warnings to disable_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:264 |
> | _notes_ | Placed directly into projects as is, with no validation. |
>
> *Examples*
>```ruby
> nowarn [4100, 4127, 4244] if visual_studio?
>```
#### objdir

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:225 |
> | _notes_ |  |
#### platform

> _Target platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:77 |
> | _notes_ | Use for querying the current target platform. |
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
#### platform_ref

> _Target platform as an object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:91 |
> | _notes_ | Use when access to platform attributes is required. |
#### platforms

> _Target platforms_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:25 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> platforms [:windows]
> platforms [:macos, :ios]
>```
#### projname

> _Base name of project files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:114 |
> | _notes_ | Defaults to $(id)$(projsuffix). |
#### projroot

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | . |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:107 |
> | _notes_ | Directory in which projects will be generated. Specified as a relative path from $(root). If not specified projects will be generated in $(root). |
#### projsuffix

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:122 |
> | _notes_ | Optional suffix to be applied to $(projname). Has no effect if $(projname) is set explicitly. |
#### root

> _Root directory relative to which all other paths are specified_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | . |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:14 |
> | _notes_ | Root of the project specified as a relative path to the file that contains the project definition. All paths are specified relative to this. Project files will be generated here unless $(projroot) is set. |
#### rtti

> _Enables runtime type information_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | true |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:340 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> rtti false # Disable rtti
>```
#### src

> _Source file specification_
> 
> | Property | Value  |
> |-|-|
> | _type_ | src_spec |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :required,:nosort |
> | _options_ | :force, :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:126 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> src ['*']  # Add all src in $(root) whose extension is in $(src_ext)
> src ['src/**/*'] # Add all src in $(root)/src whose extension is in $(src_ext), recursively
> src ['main.c', 'io.c'] # Add src explicitly
> src ['jaba.jdl.rb']  # Explicitly add even though not in $(src_ext)
> src ['does_not_exist.cpp'], :force  # Force addition of file not on disk
>```
#### src_ext

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :nosort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:142 |
> | _notes_ | File extensions that will be added when src is not specified explicitly. Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes. |
#### targetext

> _Extension to apply to $(targetname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:289 |
> | _notes_ | Defaults to standard extension for $(type) of project for target $(platform). |
#### targetname

> _Base name of output file without extension_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:271 |
> | _notes_ | Defaults to $(targetprefix)$(projname)$(targetsuffix). |
#### targetprefix

> _Prefix to apply to $(targetname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:279 |
> | _notes_ | Has no effect if $(targetname) specified. |
#### targetsuffix

> _Suffix to apply to $(targetname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:284 |
> | _notes_ | Has no effect if $(targetname) specified. |
#### toolset

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:346 |
> | _notes_ |  |
#### type

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:183 |
> | _notes_ |  |
#### vcglobal

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | hash |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_visual_studio.jdl.rb:54 |
> | _notes_ | Directly address the Globals property group in a vcxproj. |
#### vcproperty

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | hash |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_visual_studio.jdl.rb:74 |
> | _notes_ | Address config section of a vcxproj directly. |
#### warnerror

> _Enable warnings as errors_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:314 |
> | _notes_ |  |
>
> *Examples*
>```ruby
> warnerror true
>```
#### winsdkver

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_visual_studio.jdl.rb:60 |
> | _notes_ | Windows SDK version. Defaults to nil. |

---

## globals
> 
> _Global attribute definitions_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/globals.jdl.rb:1 |
> | _notes_ |  |
> 

#### vcfiletype

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _variant_ | hash |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_visual_studio.jdl.rb:2 |
> | _notes_ |  |

---

## host
> 
> _Target host_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:4 |
> | _notes_ |  |
> 

#### cpp_project_classname

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:359 |
> | _notes_ |  |
#### major_version

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:16 |
> | _notes_ |  |
#### toolset

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:19 |
> | _notes_ |  |
#### version

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:17 |
> | _notes_ |  |
#### version_year

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:18 |
> | _notes_ |  |
#### visual_studio?

> _Targeting Visual Studio?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:8 |
> | _notes_ |  |
#### vs2010?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
#### vs2012?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
#### vs2013?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
#### vs2015?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
#### vs2017?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
#### vs2019?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
#### xcode?

> _Targeting Xcode?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:12 |
> | _notes_ |  |

---

## platform
> 
> _Target platform_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:4 |
> | _notes_ |  |
> 

#### apple?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:21 |
> | _notes_ | Returns true if its an Apple platform. |
#### ios?

> _Queries target platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:9 |
> | _notes_ | Returns true if current platform is ios. |
#### macos?

> _Queries target platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:9 |
> | _notes_ | Returns true if current platform is macos. |
#### microsoft?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:16 |
> | _notes_ | Returns true if its a Microsoft platform. |
#### valid_archs

> _List of architectures supported by this platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :required,:nosort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:26 |
> | _notes_ |  |
#### windows?

> _Queries target platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:9 |
> | _notes_ | Returns true if current platform is windows. |

---

## text
> 
> _Basic text file that is written to HDD_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:1 |
> | _notes_ |  |
> 

#### content

> _Content as a single multiline string_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:10 |
> | _notes_ | Directly set content of file as a string. |
#### eol

> _End of line style_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ | native |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:20 |
> | _notes_ |  |
#### filename

> _Path of the filename to be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | file |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:5 |
> | _notes_ |  |
#### line

> _Adds a line of content to file_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :allow_dupes,:nosort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:15 |
> | _notes_ |  |

---

## workspace
> 
> _Workspace of projects_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:1 |
> | _notes_ |  |
> 

#### projects

> _Contained projects_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :nosort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:13 |
> | _notes_ | Specified by id (symbol or string), or by glob matches against $(projroot). |
#### root

> _Root directory relative to which all other paths are specified_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | . |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:7 |
> | _notes_ | Defaults to containing directory of definition source file. |

