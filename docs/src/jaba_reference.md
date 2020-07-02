# Jaba Reference

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
  - nosort
  - read_only
  - required
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
    - projdir
    - projname
    - projsuffix
    - root
    - rtti
    - shell
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
    - workspace_classname
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
    - configs
    - name
    - namesuffix
    - primary
    - projects
    - root
    - workspacedir

---

## arch
> 
> _Target architecture type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/archs.jdl.rb:3 |
> | _notes_ | Manages attribute definitions for 'arch' type.  |
> 

#### arm64?
> _Returns true if current target architecture is arm64_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### vsname
> _Name of target architecture (platform) as seen in Visual Studio IDE_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | "" |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:27 |
#### x86?
> _Returns true if current target architecture is x86_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### x86_64?
> _Returns true if current target architecture is x86_64_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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

## category
> 
> _Project category type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/category.jdl.rb:1 |
> | _notes_ | Manages attribute definitions for 'category' type.  |
> 

#### guid
> _Globally unique id (GUID)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | uuid  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:85 |
> | _notes_ | Seeded by $(name). Required by Visual Studio .sln files.  |
#### name
> _Display name of category_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/category.jdl.rb:5 |
> | _notes_ | Maps to name of solution folder in a Visual Studio solution.  |
#### parent
> _Parent category_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/category.jdl.rb:11 |
> | _notes_ | Use this to build a category hierarchy that can be used to classify projects in workspaces.  |

---

## cpp
> 
> _Cross platform C++ project definition_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:3 |
> | _notes_ | Manages attribute definitions for 'cpp' type.  |
> 

#### arch
> _Target architecture as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string  |
> | _default_ | nil |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:191 |
> | _notes_ | Query current architecture being processed. Use to define control flow to set config-specific atttributes.  |
#### arch_ref
> _Target architecture as an object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:197 |
#### archs
> _Target architectures_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array [:x86, :x86_64, :arm64] |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:63 |
>
> *Examples*
>```ruby
> archs [:x86, :x86_64]
>```
#### bindir
> _Output directory for executables_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir  |
> | _default_ |  |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:241 |
#### buildroot
> _Root directory for build artifacts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir  |
> | _default_ | "build" |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:234 |
> | _notes_ | Specified as a relative path from $(root).  |
#### cflags
> _Raw compiler command line switches_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:265 |
#### character_set
> _Character set_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice [:mbcs, :unicode, nil] |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:355 |
>
> *Examples*
>```ruby
> character_set :unicode
>```
#### config
> _Current target config as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string  |
> | _default_ | nil |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:218 |
> | _notes_ | Returns current config being processed. Use to define control flow to set config-specific atttributes.  |
#### configname
> _Display name of config as seen in IDE_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:270 |
#### configs
> _Build configurations_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array  |
> | _default_ | nil |
> | _flags_ | :required, :nosort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:70 |
>
> *Examples*
>```ruby
> configs [:Debug, :Release]
>```
#### debug
> _Flags config as a debug config_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:277 |
> | _notes_ | Defaults to true if config id contains 'debug'.  |
#### defines
> _Preprocessor defines_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:285 |
#### deps
> _Project dependencies_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference array  |
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
#### exceptions
> _Enables C++ exceptions_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice [true, false, :structured] |
> | _default_ | true |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:366 |
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
> | _type_ | uuid  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:47 |
> | _notes_ | Seeded by $(projname). Required by Visual Studio project files.  |
#### host
> _Target host as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol  |
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
#### host_ref
> _Target host as object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:51 |
> | _notes_ | Use when access to host attributes is required.  |
#### hosts
> _Target hosts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array [:vs2010, :vs2012, :vs2013, :vs2015, :vs2017, :vs2019, :xcode] |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:7 |
> | _notes_ | The following hosts are available as standard: vs2010, vs2012, vs2013, vs2015, vs2017, vs2019, xcode.  |
#### inc
> _Include paths_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir array  |
> | _default_ | nil |
> | _flags_ | :nosort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:290 |
>
> *Examples*
>```ruby
> inc ['mylibrary/include']
> inc ['mylibrary/include'], :export # Export include path to dependents
>```
#### libdir
> _Output directory for libs_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir  |
> | _default_ |  |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:249 |
#### nowarn
> _Warnings to disable_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:298 |
> | _notes_ | Placed directly into projects as is, with no validation.  |
>
> *Examples*
>```ruby
> nowarn [4100, 4127, 4244] if visual_studio?
>```
#### objdir
> _Output directory for object files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir  |
> | _default_ |  |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:257 |
#### platform
> _Target platform as an id_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol  |
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
#### platform_ref
> _Target platform as an object_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:93 |
> | _notes_ | Use when access to platform attributes is required.  |
#### platforms
> _Target platforms_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array [:windows, :ios, :macos] |
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
#### projdir
> _Directory in which projects will be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir  |
> | _default_ | "." |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:122 |
> | _notes_ | Specified as an offset from $(root). If not specified projects will be generated in $(root). Path can also be absolute but explicitly specified absolute paths should be avoided in definitions where possible in order to not damage portability.  |
>
> *Examples*
>```ruby
> cpp :MyApp do
>   src ['**/*'] # Get all src in $(root), which defaults to directory of definition file
>   projdir 'projects' # Place generated projects in 'projects' directory
> end
>       
>```
#### projname
> _Base name of project files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:137 |
> | _notes_ | Defaults to $(id)$(projsuffix).  |
#### projsuffix
> _Optional suffix to be applied to $(projname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:145 |
> | _notes_ | Has no effect if $(projname) is set explicitly.  |
#### root
> _Root directory relative to which all other paths are specified_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir  |
> | _default_ | "." |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:14 |
> | _notes_ | Root of the project specified as an offset from the file that contains the project definition. All paths are specified relative to this. Project files will be generated here unless $(projdir) is set. Path can also be absolute but explicitly specified absolute paths should be avoided in definitions where possible in order to not damage portability.  |
#### rtti
> _Enables runtime type information_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
> | _default_ | true |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:374 |
>
> *Examples*
>```ruby
> rtti false # Disable rtti
>```
#### shell
> _Shell commands to execute during build_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:227 |
> | _notes_ | Maps to build events in Visual Studio.  |
#### src
> _Source file specification_
> 
> | Property | Value  |
> |-|-|
> | _type_ | src_spec array  |
> | _default_ | nil |
> | _flags_ | :required, :nosort |
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
#### src_ext
> _File extensions used when matching src files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string array  |
> | _default_ |  |
> | _flags_ | :nosort |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:166 |
> | _notes_ | Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes..  |
#### targetext
> _Extension to apply to $(targetname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:323 |
> | _notes_ | Defaults to standard extension for $(type) of project for target $(platform).  |
#### targetname
> _Base name of output file without extension_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:305 |
> | _notes_ | Defaults to $(targetprefix)$(projname)$(targetsuffix).  |
#### targetprefix
> _Prefix to apply to $(targetname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:313 |
> | _notes_ | Has no effect if $(targetname) specified.  |
#### targetsuffix
> _Suffix to apply to $(targetname)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:318 |
> | _notes_ | Has no effect if $(targetname) specified.  |
#### toolset
> _Toolset version to use_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:380 |
> | _notes_ | Defaults to host's default toolset.  |
#### type
> _Project type_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice [:app, :console, :lib, :dll] |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:210 |
#### vcglobal
> _Address Globals property group in a vcxproj directly_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s hash  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:55 |
#### vcproperty
> _Address per-configuration sections of a vcxproj directly_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s hash  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:76 |
#### warnerror
> _Enable warnings as errors_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
> | _default_ | false |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:348 |
>
> *Examples*
>```ruby
> warnerror true
>```
#### winsdkver
> _Windows SDK version_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice ["10.0.16299.0", "10.0.17134.0", "10.0.17763.0", "10.0.18362.0", nil] |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:61 |

---

## globals
> 
> _Global attribute definitions_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/globals.jdl.rb:1 |
> | _notes_ | Manages attribute definitions for 'globals' type.  |
> 

#### vcfiletype
> _Visual C++ file types_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol hash  |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/VisualStudio/cpp_vs.jdl.rb:2 |

---

## host
> 
> _Target host type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:4 |
> | _notes_ | Manages attribute definitions for 'host' type.  |
> 

#### cpp_project_classname
> _Class name of host-specific Project subclass_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/cpp/cpp.jdl.rb:391 |
> | _notes_ | For example Vcxproj, Xcodeproj. Use when implementing a new project type..  |
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
#### toolset
> _Default toolset for host_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:25 |
#### version
> _Host version string_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:19 |
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
#### visual_studio?
> _Targeting Visual Studio?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:8 |
#### vs2010?
> _Returns true if current target host is vs2010_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### vs2012?
> _Returns true if current target host is vs2012_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### vs2013?
> _Returns true if current target host is vs2013_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### vs2015?
> _Returns true if current target host is vs2015_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### vs2017?
> _Returns true if current target host is vs2017_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### vs2019?
> _Returns true if current target host is vs2019_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### workspace_classname
> _Class name of host-specific Workspace subclass_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:52 |
> | _notes_ | For example Sln, XcodeWorkspace. Use when implementing a new workspace type..  |
#### xcode?
> _Targeting Xcode?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/hosts.jdl.rb:12 |

---

## platform
> 
> _Target platform type_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:4 |
> | _notes_ | Manages attribute definitions for 'platform' type. Manages attribute definitions required by platforms.  |
> 

#### apple?
> _Returns true if current target platform is an Apple platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:27 |
> | _notes_ | Use only if attribute being set works across all current and future apple platforms. As such probably rarely used..  |
#### ios?
> _Returns true if current target platform is ios_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### macos?
> _Returns true if current target platform is macos_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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
#### microsoft?
> _Returns true if current target platform is a Microsoft platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:22 |
#### valid_archs
> _List of architectures supported by this platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice array [:x86, :x86_64, :arm64] |
> | _default_ | nil |
> | _flags_ | :required, :nosort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/core/platforms.jdl.rb:34 |
#### windows?
> _Returns true if current target platform is windows_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool  |
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

## text
> 
> _Basic text file that is written to HDD_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:1 |
> | _notes_ | Manages attribute definitions for 'text' type.  |
> 

#### content
> _Content as a single multiline string_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s  |
> | _default_ | nil |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:10 |
> | _notes_ | Directly set content of file as a string..  |
#### eol
> _End of line style_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice [:lf, :crlf, :native] |
> | _default_ | :native |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:20 |
#### filename
> _Path of the filename to be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | file  |
> | _default_ | nil |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:5 |
#### line
> _Adds a line of content to file_
> 
> | Property | Value  |
> |-|-|
> | _type_ | to_s array  |
> | _default_ | nil |
> | _flags_ | :allow_dupes, :nosort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/text/text.jdl.rb:15 |

---

## workspace
> 
> _Workspace of projects_
> 
> | Property | Value  |
> |-|-|
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:1 |
> | _notes_ | Manages attribute definitions for 'workspace' type.  |
> 

#### configs
> _Solution configurations_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array  |
> | _default_ | nil |
> | _flags_ | :nosort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:44 |
#### name
> _Base name of workspace files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:27 |
#### namesuffix
> _Optional suffix to be applied to $(name)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string  |
> | _default_ | "" |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:34 |
> | _notes_ | Has no effect if $(name) is set explicitly.  |
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
#### projects
> _Contained projects_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string array  |
> | _default_ | nil |
> | _flags_ | :required, :nosort |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:19 |
> | _notes_ | Specified by id (symbol or string), or by glob matches against $(projdir).  |
#### root
> _Root directory relative to which all other paths are specified_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir  |
> | _default_ | "." |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:7 |
> | _notes_ | Defaults to containing directory of definition source file.  |
#### workspacedir
> _Directory in which workspaces will be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir  |
> | _default_ | "." |
> | _flags_ | :no_check_exist |
> | _options_ |  |
> | _src_ | $(jaba_install)/modules/workspace/workspace.jdl.rb:13 |

