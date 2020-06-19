# Jaba Reference

- Attribute types
  - string
  - symbol
  - symbol_or_string
  - bool
  - choice
  - dir
  - file
  - src_spec
  - reference
  - uuid
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
> | _src_ | C:/projects/GitHub/jaba/lib/jaba/extend/generator.rb |
> | _notes_ |  |
> 

#### arm64?

> _Query target architecture type_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/core/archs.jdl.rb:8 |
> | _notes_ | Returns true if current architecture is arm64. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/VisualStudio/cpp_visual_studio.jdl.rb:26 |
> | _notes_ | Name of target architecture (platform) as seen in Visual Studio IDE. |
> 

```ruby
```
#### x86?

> _Query target architecture type_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/core/archs.jdl.rb:8 |
> | _notes_ | Returns true if current architecture is x86. |
> 

```ruby
```
#### x86_64?

> _Query target architecture type_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | :expose |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/core/archs.jdl.rb:8 |
> | _notes_ | Returns true if current architecture is x86_64. |
> 

```ruby
```

---

## category
> 
> _Project category_
> 
> | Property | Value  |
> |-|-|
> | _src_ | C:/projects/GitHub/jaba/lib/jaba/extend/generator.rb |
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
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/core/category.jdl.rb:11 |
> | _notes_ | Must be of the form '0376E589-F783-4B80-DA86-705F2E05304E'. Required by Visual Studio .sln files. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/category.jdl.rb:5 |
> | _notes_ | Maps to name of solution folder in a Visual Studio solution. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/category.jdl.rb:17 |
> | _notes_ | Use this to build a category hierarchy that can be used to classify projects in workspaces. |
> 

```ruby
```

---

## cpp
> 
> _Cross platform C++ project definition_
> 
> | Property | Value  |
> |-|-|
> | _src_ | C:/projects/GitHub/jaba/modules/cpp/cpp_generator.rb |
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:151 |
> | _notes_ | Returns current arch being processed. Use to define control flow to set config-specific atttributes. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:156 |
> | _notes_ |  |
> 

```ruby
```
#### archs

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:46 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:196 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:182 |
> | _notes_ | Build action, eg a prebuild step. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:189 |
> | _notes_ | Specified as a relative path from <root>. |
> 

```ruby
```
#### cflags

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:217 |
> | _notes_ | Raw compiler command line switches. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:298 |
> | _notes_ | Character set. Defaults to :unicode. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:175 |
> | _notes_ | Returns current config being processed. Use to define control flow to set config-specific atttributes. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:222 |
> | _notes_ | Display name of config in Visual Studio. Defaults to <config>. |
> 

```ruby
```
#### configs

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :required,:nosort |
> | _options_ | :export |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:51 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:227 |
> | _notes_ | Flags config as a debug build. Defaults to true if config id contains 'debug'. |
> 

```ruby
```
#### defines

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ |  |
> | _options_ | :export |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:234 |
> | _notes_ | Preprocessor defines. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:72 |
> | _notes_ | Specify project dependencies. List of ids of other cpp definitions. |
> 

```ruby
```
#### exceptions

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ | true |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:308 |
> | _notes_ | Enables C++ exceptions. On by default. |
> 

```ruby
```
#### host

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | :read_only |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:32 |
> | _notes_ |  |
> 

```ruby
```
#### host_ref

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:36 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:7 |
> | _notes_ | The following hosts are available as standard: vs2010, vs2012, vs2013, vs2015, vs2017, vs2019, xcode. |
> 

```ruby
```
#### inc

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :nosort |
> | _options_ | :export |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:239 |
> | _notes_ | Include paths. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:203 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:245 |
> | _notes_ | Placed directly into projects as is, with no validation. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:210 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:58 |
> | _notes_ | Use for querying the current target platform. |
> 

```ruby
```
#### platform_ref

> _Target platform node_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:64 |
> | _notes_ | Use when access to platform attributes is required. |
> 

```ruby
```
#### platforms

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | :required |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:25 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:87 |
> | _notes_ | Defaults to <id><projsuffix>. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:80 |
> | _notes_ | Directory in which projects will be generated. Specified as a relative path from <root>. If not specified projects will be generated in <root>. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:93 |
> | _notes_ | Optional suffix to be applied to <projname>. Has no effect if <projname> is set explicitly. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:14 |
> | _notes_ | Root of the project specified as a relative path to the file that contains the project definition. All paths are specified relative to this. Project files will be generated here unless <projroot> is set. |
> 

```ruby
```
#### rtti

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | true |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:315 |
> | _notes_ | Enable runtime type information. On by default. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:97 |
> | _notes_ |  |
> 

```ruby
src ['*']  # Add all src in <root> whose extension is in <src_ext>
src ['jaba.jdl.rb']  # Explicitly add even though not in <src_ext>
src ['does_not_exist.cpp'], :force  # Force addition of file not on disk
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:109 |
> | _notes_ | File extensions that will be added when src is not specified explicitly. Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes. |
> 

```ruby
```
#### targetext

> _Extension to apply to <targetname>_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:267 |
> | _notes_ | Defaults to standard extension for <type> of project for target <platform>. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:251 |
> | _notes_ | Defaults to <targetprefix><targetname><projname><targetsuffix>. |
> 

```ruby
```
#### targetprefix

> _Prefix to apply to <targetname>_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:257 |
> | _notes_ | Has no effect if <targetname> specified. |
> 

```ruby
```
#### targetsuffix

> _Suffix to apply to <targetname>_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:262 |
> | _notes_ | Has no effect if <targetname> specified. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:320 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:168 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:141 |
> | _notes_ | Directly address the Globals property group in a vcxproj. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:324 |
> | _notes_ | Address config section of a vcxproj directly. |
> 

```ruby
```
#### warnerror

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ |  |
> | _options_ |  |
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:292 |
> | _notes_ | Enable warnings as errors. Off by default. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:129 |
> | _notes_ | Windows SDK version. Defaults to nil. |
> 

```ruby
```

---

## globals
> 
> _Global attribute definitions_
> 
> | Property | Value  |
> |-|-|
> | _src_ | C:/projects/GitHub/jaba/lib/jaba/extend/generator.rb |
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
> | _src_ | <jaba_install>/modules/cpp/VisualStudio/cpp_visual_studio.jdl.rb:2 |
> | _notes_ |  |
> 

```ruby
```

---

## host
> 
> _Target host_
> 
> | Property | Value  |
> |-|-|
> | _src_ | C:/projects/GitHub/jaba/lib/jaba/extend/generator.rb |
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
> | _src_ | <jaba_install>/modules/cpp/cpp.jdl.rb:340 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:16 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:19 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:17 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:18 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:8 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:22 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/hosts.jdl.rb:12 |
> | _notes_ |  |
> 

```ruby
```

---

## platform
> 
> _Target platform_
> 
> | Property | Value  |
> |-|-|
> | _src_ | C:/projects/GitHub/jaba/lib/jaba/extend/generator.rb |
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
> | _src_ | <jaba_install>/modules/core/platforms.jdl.rb:21 |
> | _notes_ | Returns true if its an Apple platform. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/platforms.jdl.rb:9 |
> | _notes_ | Returns true if current platform is ios. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/platforms.jdl.rb:9 |
> | _notes_ | Returns true if current platform is macos. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/platforms.jdl.rb:16 |
> | _notes_ | Returns true if its a Microsoft platform. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/platforms.jdl.rb:26 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/core/platforms.jdl.rb:9 |
> | _notes_ | Returns true if current platform is windows. |
> 

```ruby
```

---

## text
> 
> _Basic text file that is written to HDD_
> 
> | Property | Value  |
> |-|-|
> | _src_ | C:/projects/GitHub/jaba/modules/text/text_generator.rb |
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
> | _src_ | <jaba_install>/modules/text/text.jdl.rb:10 |
> | _notes_ | Directly set content of file as a string. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/text/text.jdl.rb:20 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/text/text.jdl.rb:5 |
> | _notes_ |  |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/text/text.jdl.rb:15 |
> | _notes_ |  |
> 

```ruby
```

---

## workspace
> 
> _Workspace of projects_
> 
> | Property | Value  |
> |-|-|
> | _src_ | C:/projects/GitHub/jaba/modules/workspace/workspace_generator.rb |
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
> | _src_ | <jaba_install>/modules/workspace/workspace.jdl.rb:13 |
> | _notes_ | Specified by id (symbol or string), or by glob matches against <projroot>. |
> 

```ruby
```
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
> | _src_ | <jaba_install>/modules/workspace/workspace.jdl.rb:7 |
> | _notes_ | Defaults to containing directory of definition source file. |
> 

```ruby
```

