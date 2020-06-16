# Jaba Type Reference
Defines what instances can be made with what attributes

---

## globals


#### vcfiletype

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _variant_ | hash |
> | _default_ |  |
> | _flags_ | required
> | _options_ |  |
> 


---

## arch


#### arm64?

> _Query target architecture type_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns true if current architecture is arm64

#### vsname

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | expose
> | _options_ |  |
> 
> _**Notes**_
> 
> Name of target architecture (platform) as seen in Visual Studio IDE

#### x86?

> _Query target architecture type_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns true if current architecture is x86

#### x86_64?

> _Query target architecture type_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns true if current architecture is x86_64


---

## category


#### guid

> _Globally unique id (GUID)_
> 
> | Property | Value  |
> |-|-|
> | _type_ | uuid |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | required
> | _options_ |  |
> 
> _**Notes**_
> 
> Must be of the form '0376E589-F783-4B80-DA86-705F2E05304E'. Required by Visual Studio .sln files

#### name

> _Display name of category_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | required
> | _options_ |  |
> 
> _**Notes**_
> 
> Maps to name of solution folder in a Visual Studio solution

#### parent

> _Parent category_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Use this to build a category hierarchy that can be used to classify projects in workspaces


---

## host


#### cpp_project_classname

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | required
> | _options_ |  |
> 

#### major_version

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 

#### toolset

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 

#### version

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 

#### version_year

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 

#### visual_studio?

> _Targeting Visual Studio?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 

#### vs2010?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 

#### vs2012?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 

#### vs2013?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 

#### vs2015?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 

#### vs2017?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 

#### vs2019?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 

#### xcode?

> _Targeting Xcode?_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 


---

## platform


#### apple?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns true if its an Apple platform

#### ios?

> _Queries target platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns true if current platform is ios

#### macos?

> _Queries target platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns true if current platform is macos

#### microsoft?

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns true if its a Microsoft platform

#### valid_archs

> _List of architectures supported by this platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | required,nosort
> | _options_ |  |
> 

#### windows?

> _Queries target platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | expose
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns true if current platform is windows


---

## cpp

        generator: C:/projects/GitHub/jaba/modules/cpp/cpp_generator.rb

#### hosts

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | required
> | _options_ |  |
> 

#### root

> _Root directory relative to which all other paths are specified_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | . |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Root of the project specified as a relative path to the file that contains the project definition. All paths are specified relative to this. Project files will be generated here unless <projroot> is set.

#### platforms

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | required
> | _options_ |  |
> 

#### host

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | read_only
> | _options_ |  |
> 

#### host_ref

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 

#### archs

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | required
> | _options_ |  |
> 

#### configs

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | required,nosort
> | _options_ | export |
> 

#### platform

> _Target platform_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | read_only
> | _options_ |  |
> 
> _**Notes**_
> 
> Use for querying the current target platform

#### platform_ref

> _Target platform node_
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Use when access to platform attributes is required

#### deps

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Specify project dependencies. List of ids of other cpp definitions.

#### projroot

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | . |
> | _flags_ | no_check_exist
> | _options_ |  |
> 
> _**Notes**_
> 
> Directory in which projects will be generated. Specified as a relative path from <root>. If not specified projects will be generated in <root>

#### projname

> _Base name of project files_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ | #<Proc:0x000000000654c8a0 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:88> |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Defaults to <id><projsuffix>.

#### projsuffix

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Optional suffix to be applied to <projname>. Has no effect if <projname> is set explicitly.

#### src

> _Source file specification_
> 
> | Property | Value  |
> |-|-|
> | _type_ | src_spec |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | required,nosort
> | _options_ | force, export |
> 

#### src_ext

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | array |
> | _default_ | #<Proc:0x000000000655a658 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:109> |
> | _flags_ | nosort
> | _options_ | export |
> 
> _**Notes**_
> 
> File extensions that will be added when src is not specified explicitly. Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes.

#### winsdkver

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Windows SDK version. Defaults to nil.

#### vcglobal

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | hash |
> | _default_ |  |
> | _flags_ | 
> | _options_ | export |
> 
> _**Notes**_
> 
> Directly address the Globals property group in a vcxproj

#### arch

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | read_only
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns current arch being processed. Use to define control flow to set config-specific atttributes

#### arch_ref

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | reference |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 

#### type

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | required
> | _options_ |  |
> 

#### config

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | read_only
> | _options_ |  |
> 
> _**Notes**_
> 
> Returns current config being processed. Use to define control flow to set config-specific atttributes

#### build_action

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | 
> | _options_ | export |
> 
> _**Notes**_
> 
> Build action, eg a prebuild step

#### buildroot

> _Root directory for build artifacts_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | build |
> | _flags_ | no_check_exist
> | _options_ |  |
> 
> _**Notes**_
> 
> Specified as a relative path from <root>

#### bindir

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | #<Proc:0x0000000006534408 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:192> |
> | _flags_ | no_check_exist
> | _options_ |  |
> 

#### libdir

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | #<Proc:0x000000000652b970 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:199> |
> | _flags_ | no_check_exist
> | _options_ |  |
> 

#### objdir

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | #<Proc:0x000000000652ad68 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:206> |
> | _flags_ | no_check_exist
> | _options_ |  |
> 

#### cflags

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | 
> | _options_ | export |
> 
> _**Notes**_
> 
> Raw compiler command line switches

#### configname

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ | #<Proc:0x00000000065297b0 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:219> |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Display name of config in Visual Studio. Defaults to <config>

#### debug

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | #<Proc:0x0000000006528f18 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:224> |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Flags config as a debug build. Defaults to true if config id contains 'debug'

#### defines

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | 
> | _options_ | export |
> 
> _**Notes**_
> 
> Preprocessor defines

#### inc

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | nosort
> | _options_ | export |
> 
> _**Notes**_
> 
> Include paths

#### nowarn

> _Warnings to disable_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | 
> | _options_ | export |
> 
> _**Notes**_
> 
> Placed directly into projects as is, with no validation

#### targetname

> _Base name of output file without extension_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ | #<Proc:0x0000000006522d48 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:249> |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Defaults to <targetprefix><targetname><projname><targetsuffix>

#### targetprefix

> _Prefix to apply to <targetname>_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Has no effect if <targetname> specified

#### targetsuffix

> _Suffix to apply to <targetname>_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Has no effect if <targetname> specified

#### targetext

> _Extension to apply to <targetname>_
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ | #<Proc:0x0000000006520d18 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:265> |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Defaults to standard extension for <type> of project for target <platform>

#### warnerror

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | false |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Enable warnings as errors. Off by default.

#### character_set

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Character set. Defaults to :unicode

#### exceptions

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ | true |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Enables C++ exceptions. On by default.

#### rtti

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | bool |
> | _variant_ | single |
> | _default_ | true |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Enable runtime type information. On by default.

#### toolset

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ | string |
> | _variant_ | single |
> | _default_ | #<Proc:0x00000000064fcff8 C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:316> |
> | _flags_ | 
> | _options_ |  |
> 

#### vcproperty

> __
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | hash |
> | _default_ |  |
> | _flags_ | 
> | _options_ | export |
> 
> _**Notes**_
> 
> Address config section of a vcxproj directly


---

## text

        generator: C:/projects/GitHub/jaba/modules/text/text_generator.rb

#### content

> _Content as a single multiline string_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Directly set content of file as a string.

#### eol

> _End of line style_
> 
> | Property | Value  |
> |-|-|
> | _type_ | choice |
> | _variant_ | single |
> | _default_ | native |
> | _flags_ | 
> | _options_ |  |
> 

#### filename

> _Path of the filename to be generated_
> 
> | Property | Value  |
> |-|-|
> | _type_ | file |
> | _variant_ | single |
> | _default_ |  |
> | _flags_ | required
> | _options_ |  |
> 

#### line

> _Adds a line of content to file_
> 
> | Property | Value  |
> |-|-|
> | _type_ |  |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | allow_dupes,nosort
> | _options_ |  |
> 


---

## workspace

        generator: C:/projects/GitHub/jaba/modules/workspace/workspace_generator.rb

#### projects

> _Contained projects_
> 
> | Property | Value  |
> |-|-|
> | _type_ | symbol_or_string |
> | _variant_ | array |
> | _default_ |  |
> | _flags_ | nosort
> | _options_ |  |
> 
> _**Notes**_
> 
> Specified by id (symbol or string), or by glob matches against <projroot>

#### root

> _Root directory relative to which all other paths are specified_
> 
> | Property | Value  |
> |-|-|
> | _type_ | dir |
> | _variant_ | single |
> | _default_ | . |
> | _flags_ | 
> | _options_ |  |
> 
> _**Notes**_
> 
> Defaults to containing directory of definition source file


