JDL.node "target" do
  title "Define a target"
end

JDL.attr "target/configs", variant: :array, type: :string do
  title "Build configurations"
  flags :node_option, :overwrite_default
  default [:debug, :release]
  example "configs [:debug, :release]"
end

JDL.attr "target/config", type: :string do
  title "Current target config as an id"
  note "Returns current config being processed. Use to define control flow to set config-specific atttributes"
  flags :read_only
  # TODO: examples, including regexes
end

JDL.attr "target/configname", type: :string do
  title "Display name of config as seen in IDE"
  default do
    config.capitalize_first
  end
end
  
JDL.attr "target/deps", variant: :array, type: :string do
  title "Target dependencies"
  note 'List of ids of other cpp definitions. When a dependency is specified all the dependency\'s exports ' \
        "will be imported, the library will be linked to and a project level dependency created (unless :soft specified). " \
        "To prevent linking specify :nolink - useful if only headers are required. A hard dependency is the default." \
        'This can be used for \'header only\' dependencies'
  flags :per_target, :no_sort
  flag_option :nolink do
    title "TODO"
    note "TODO"
  end
  option :type, type: :choice do
    title "Dependency type"
    items [:hard, :soft]
    default :hard
  end
  example %Q{
    target :MyApp do
      type :app
      ...
      deps [:MyLib]
      deps [:MyLib2], type: :soft # No hard project dependency so not required in workspace
    end
      
    target :MyLib do
      type :lib
      ...
    end

    target :MyLib2 do
      type :lib
      inc ['.'], :export
      define ['MYLIB2'], :export
      ...
    end
  }
end

JDL.attr "target/projdir", type: :dir do
  title "Directory in which projects will be generated"
  flags :per_target, :no_check_exist
  base_attr :buildsystem_root
  example %Q{
    target :MyApp do
      src ['**/*'] # Get all src in $(root), which defaults to directory of definition file
      projdir 'projects' # Place generated projects in 'projects' directory
    end
  }
end

JDL.attr "target/projname", type: :basename do
  title "Base name of project files"
  note "Defaults to $(id)$(projsuffix)"
  flags :per_target
  default do
    "#{id}#{projsuffix}"
  end
end

JDL.attr "target/projsuffix", type: :string do
  title "Optional suffix to be applied to $(projname)"
  note "Has no effect if $(projname) is set explicitly"
  flags :per_target
end

JDL.attr "target/cpplang", type: :choice do
  title "C++ language standard"
  items ["C++11", "C++14", "C++17", "C++20", "C++23"]
  default "C++20"
end

JDL.attr "target/bindir", type: :dir do
  title "Output directory for executables"
  flags :no_check_exist
  base_attr :artefact_root
  default do
    "#{arch}/bin/#{config}"
  end
end

JDL.attr "target/libdir", type: :dir do
  title "Output directory for libs"
  flags :no_check_exist
  base_attr :artefact_root
  default do
    "#{arch}/lib/#{config}"
  end
end

JDL.attr "target/objdir", type: :dir do
  title "Output directory for object files"
  flags :no_check_exist
  base_attr :artefact_root
  default do
    "#{arch}/obj/#{config}/#{projname}"
  end
  note "Defaults to $(artefact_root)/$(arch)/obj/$(config)/$(projname)"
end

JDL.attr "target/debug", type: :bool do
  title "Flags config as a debug config"
  note 'Defaults to true if config id contains \'debug\''
  default do
    config =~ /debug/i ? true : false
  end
end

JDL.attr "target/charset", type: :choice do
  title "Character set"
  items [
    :ascii,
    :mbcs,    # Visual Studio only
    :unicode,
  ]
  default :unicode
  example "charset :unicode"
end

JDL.attr "target/cflags", variant: :array, type: :string do
  title "Raw compiler command line switches"
  flags :exportable
end

JDL.attr "target/lflags", variant: :array, type: :string do
  title "Raw linker command line switches"
  flags :exportable
end

JDL.attr "target/define", variant: :array, type: :string do
  title "Preprocessor defines"
  flags :exportable
  example "define \"MYDEFINE\""
  example "define [\"DEFINE1\", \"DEFINE2\", \"DEFINE3=1\"]"
  example "define debug? ? \"DEBUG\" : \"RELEASE\""
end

JDL.method "target/glob" do
  title "Glob for files"
end

JDL.attr "target/inc", variant: :array, type: :dir do
  title "Include paths"
  base_attr :root
  flags :no_sort, :exportable
  example "inc ['mylibrary/include']"
  example "inc ['mylibrary/include'], :export # Export include path to dependents"
end

JDL.attr "target/exceptions", type: :choice do
  title "Enables C++ exceptions"
  items [true, false]
  items [:structured] # Windows only
  default true
  example "exceptions false # disable exceptions"
end

JDL.attr "target/pch", type: :rel_path do
  title "Precompiled header file"
  base_attr :root
  note "In Visual Studio this must be the exact string inside the #include statement in each src file"
end

JDL.attr "target/pchsrc", type: :file do
  title "Precompiled source file"
  base_attr :root
end

JDL.attr "target/rtti", type: :bool do
  title "Enables runtime type information"
  example "rtti true"
end

JDL.attr "target/rule", variant: :array, type: :compound do
  title "TODO"
end

JDL.attr "target/rule/input", variant: :array, type: :src do
  title "TODO"
  base_attr :root
  option :vpath, type: :rel_path do
    title "Virtual path"
    note "Controls IDE project layout"
  end
end

# TODO: shouldn't this be array?
JDL.attr "target/rule/implicit_input", type: :file do
  title "Implicit input files"
  base_attr :root
end

# TODO: shouldn't this be array?
JDL.attr "target/rule/output", type: :file do
  title "Output files"
  base_attr :root
  flags :required, :no_check_exist
  option :vpath, type: :rel_path do
    title "Virtual path"
    note "Controls IDE project layout"
  end
  option :properties, variant: :hash, type: :to_s do
    title "Per-file property"
    note "In the form 'src <file>, properties: {name: :value}'"
  end
end

JDL.attr "target/rule/cmd", type: :string do
  title "Command line to execute"
  flags :required
  flag_option :absolute do
    title "TODO"
    note "TODO"
  end
  note "Use :absolute to make usage of $(input) or $(output) in the command line use absolute paths. " \
        "Otherwise they will be relative to the generated project."
end

JDL.attr "target/rule/msg", type: :string do
  title "Message"
  note "Message that will be echoed to console on execution of the rule."
  note "Certain characters like < > | & are automatically escaped to prevent unwanted side effects such as writing text to a file - " \
        "this is a common reason why Visual Studio users are sometimes baffled as to why their custom build tool messages are not being printed."
end

JDL.attr "target/shell", variant: :array, type: :string do
  title "Shell commands to execute during build"
  note "Maps to build events in Visual Studio"
  flags :exportable
  option :when, type: :choice do
    title "When shell command should be run"
    items [:PreBuild, :PreLink, :PostBuild]
  end
end

JDL.attr "target/src", variant: :array, type: :src do
  title "Specify source files"
  base_attr :root
  flags :exportable, :no_sort # sorted at project generation time
  option :vpath, type: :rel_path do
    title "Virtual path"
    note "Controls IDE project layout"
  end
  option :properties, variant: :hash, type: :to_s do
    title "Per-file property"
    note "In the form 'src <file>, properties: {name: :value}'"
  end
  example %Q{
    # Add all src in $(root) whose extension is in $(src_ext)
    src ['*']

    # Add all src in $(root)/src whose extension is in $(src_ext), recursively
    src ['src/**/*']

    # Glob matches are not required to add whole directory recursively (whose extension is in $(src_ext))
    src ['src']

    # Add all src recursively but excluding test files
    src ['src'], exclude: ['test/**/*']

    # Add src explicitly
    src ['main.c', 'io.c']

    # Array brackets not required for one item
    src 'main.c'

    # Add src explicitly even if extension not in $(src_ext)
    src ['build.jaba']

    # Add src by glob match even if extension not in $(src_ext) only if has explicit extension
    src ['*.jaba']

    # Force addition of file not on disk
    src ['does_not_exist.cpp'], :force

    # Precede with ./ to force path to be relative to current jaba file even if $(root) points elsewhere.
    # Useful if you want to make $(root) point to a 3rd party distro but you want to add a local file
    src ['./local.cxx']

    # Add src in bulk without needing quotes, commas or square brackets. Options can be added as normal.
    src %w(main.c dmydln.c miniinit.c array.c ast.c bignum.c class.c compar.c compile.c)
    src %w(
      main.c dmydln.c miniinit.c array.c
      ast.c bignum.c class.c compar.c compile.c
    )

    # Place matching files in a specific folder location within the project file
    src '*_win.cpp', vpath: 'win32'

    # Set a per-file property or properties
    src 'main.cpp', properties: {MyPropertyName1: :MyPropertyValue1, MyPropertyName2: :MyPropertyValue2}
  }
end

JDL.attr "target/write_src", variant: :array, type: :compound do
  title "Creates a src and adds to build"
  on_set do
    filename = fn
      
    fm = JABA.context.file_manager
    # write_file is called on a per-config basis so it has access to all attrs but
    # don't write subsequent files with the same name
    if !fm.file_created?(filename)
      fm.new_file(filename) do |w|
        w << line.join("\n")
      end
    end
      
    vp = option_value(:fn, :vpath)
    props = option_value(:fn, :properties) || {}
    if vp
      src filename, vpath: vp, properties: props
    else
      src filename, properties: props
    end
  end
end

JDL.attr "target/write_src/fn", type: :file do
  title "Filename"
  flags :no_check_exist
  option :properties, variant: :hash, type: :to_s do
    title "Per-file property"
    note "In the form 'src <file>, properties: {name: :value}'"
  end
  option :vpath, type: :rel_path do
    title "Virtual path"
    note "Controls IDE project layout"
  end
end

JDL.attr "target/write_src/line", variant: :array, type: :to_s do
  title "Line to add to file"
end

JDL.attr "target/libs", variant: :array, type: :file do
  title "Paths to required non-system libs"
  base_attr :root
  flags :no_sort, :exportable
end

JDL.attr "target/syslibs", variant: :array, type: :string do
  title "System libs"
  flags :no_sort, :exportable
end

JDL.attr "target/targetname", type: :basename do
  title "Basename of output file without extension"
  note "Defaults to $(targetprefix)$(projname)$(targetsuffix)"
  default do
    "#{targetprefix}#{projname}#{targetsuffix}"
  end
end

JDL.attr "target/targetprefix", type: :string do
  title "Prefix to apply to $(targetname)"
  note "Has no effect if $(targetname) specified"
end

JDL.attr "target/targetsuffix", type: :string do
  title "Suffix to apply to $(targetname)"
  note "Has no effect if $(targetname) specified"
end

JDL.attr "target/targetext", type: :ext do
  title "Extension to apply to $(targetname)"
  note "Defaults to standard extension for $(type) of project for target $(platform)"
  default do
    case platform
    when :windows
      case type
      when :app, :console
        ".exe"
      when :lib
        ".lib"
      when :dll
        ".dll"
      end
    else
      fail "Unhandled platform '#{platform}'"
    end
  end
end

JDL.attr "target/type", type: :choice do
  title "Target type"
  items [:app, :console, :lib, :dll]
  default :console
end

JDL.attr "target/virtual", type: :bool do
  title "Virtual"
  flags :node_option
  note "Virtual targets do not inherit defaults"
end
  
JDL.attr "target/warnerror", type: :bool do
  title "Enable warnings as errors"
  example "warnerror true"
end

# VisualC per-target attributes

JDL.attr "target/vcguid", type: :uuid do
  title "Globally unique id (GUID)"
  note "Seeded by $(projname). Required by Visual Studio project files"
  flags :per_target
  default do
    projname
  end
end

JDL.attr "target/vcglobal", variant: :hash, type: :to_s do
  title "Address Globals property group in a vcxproj directly"
  key_type :string
  flags :per_target, :exportable
  option :condition, type: :string do
    title "Condition"
  end
end

JDL.attr "target/vc_extension_settings", variant: :hash, type: :file do
  title "Path to a .props file"
  key_type :ext
  flags :per_target
  base_attr :root
end

JDL.attr "target/vc_extension_targets", variant: :hash, type: :file do
  title "Path to a .targets file"
  key_type :ext
  flags :per_target
  base_attr :root
end

JDL.attr "target/winsdkver", type: :choice do
  title "Windows SDK version"
  flags :per_target
  items [
    "10.0.16299.0",  # Included in VS2017 ver.15.4
    "10.0.17134.0",  # Included in VS2017 ver.15.7
    "10.0.17763.0",  # Included in VS2017 ver.15.8
    "10.0.18362.0",  # Included in VS2019
    nil,
  ]
  default nil
  example "winsdkver '10.0.18362.0'"
  example "# wrapper for"
  example "vcglobal :WindowsTargetPlatformVersion, winsdkver"
end

# VisualC Per-config attributes

JDL.attr "target/vcimportlib", type: :file do
  title "Name of import lib for use will dlls"
  flags :no_check_exist
  note "Defaults to $(projname)$(targetsuffix).lib"
  default do
    "#{projname}#{targetsuffix}.lib"
  end
  base_attr :libdir
end

JDL.attr "target/vcwarnlevel", type: :choice do
  title "Visual Studio warning level"
  items [1, 2, 3, 4]
  default 3
end

JDL.attr "target/vcnowarn", variant: :array, type: :int do
  title "Warnings to disable"
  flags :exportable
  example "vcnowarn [4100, 4127, 4244]"
end

JDL.attr "target/vcprop", variant: :hash, type: :to_s do
  title "Address per-configuration sections of a vcxproj directly"
  key_type :string
  flags :exportable
  option :condition, type: :string do
    title "Condition string"
  end
  validate_key do |key|
    if key !~ /^[A-Za-z0-9_-]+\|{1}[A-Za-z0-9_-]+/
      fail "Must be of form <group>|<property> but was '#{key}'"
    end
  end
  example %Q{
    # Insert property into first PropertyGroup section (the one that contains ConfigurationType)
    vcprop 'PG1|MyProperty', 'MyValue'

    # Insert property into second PropertyGroup section
    vcprop 'PG2|MyProperty2', 10

    # Insert boolean property into ClCompile section
    vcprop 'ClCompile|BufferSecurityCheck', false

    # Can use a symbol for property value. Same result as using quoted string.
    vcprop 'Link|EntryPointSymbol', :mainCRTStartup

    vcprop 'Midl|SuppressStartupBanner, true
  }
end

JDL.attr "target/vctoolset", type: :choice do
  title "Toolset version to use"
  note "Defaults to default platform toolset for version of Visual Studio in use"
  items ['$(DefaultPlatformToolset)', "v100", "v110", "v120", "v140", "v141", "v142", "v143"]
  default '$(DefaultPlatformToolset)'
end
  
JDL.node "workspace" do
  title "Define a workspace"
end

JDL.attr "workspace/dir", type: :dir do
  title 'Directory in which workspaces will be generated'
  base_attr :buildsystem_root
  flags :no_check_exist # May get created during generation
end

JDL.attr "workspace/targets", variant: :array, type: :string do
  title "Targets to add to workspace"
  flags :required, :no_sort
end

JDL.attr "workspace/name", type: :string do
  title "Basename of workspace files"
  note "Defaults to $(id)$(namesuffix)"
  default do
    "#{id}#{namesuffix}"
  end
end

JDL.attr "workspace/namesuffix", type: :string do
  title "Optional suffix to be applied to $(name)"
  note "Has no effect if $(name) is set explicitly"
end
