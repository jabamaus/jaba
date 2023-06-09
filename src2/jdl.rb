JABA.define_jdl do

  global_method "__dir__" do
    title "Returns the directory of the currently executing .jaba file"
  end

  global_method "available" do
    title "Array of attributes/methods available in current scope"
  end

  global_method "fail" do
    title "Raise an error"
    note "Stops execution"
    on_called do |msg| JABA.error(msg, line: $last_call_location) end
  end

  global_method "include" do
    title "Include a shared definition or a .jaba file"
    note "Use at file scope to include another .jaba file or inside definition blocks to include 'shared' definitions"
  end

  global_method "print" do
    title "Prints a non-newline terminated string to stdout"
    on_called do |str| Kernel.print(str) end
  end

  global_method "puts" do
    title "Prints a newline terminated string to stdout"
    on_called do |str| Kernel.puts(str) end
  end

  global_method "x86_64?" do
    title "Returns true if targeting x86_64"
    on_called do
      JABA.context.root_node[:arch] == :x86_64
    end
  end

  global_method "windows?" do
    title "Returns true if targeting windows"
    on_called do
      JABA.context.root_node[:platform] == :windows
    end
  end
  
  # Top level methods

  method "glob" do
    title "glob files"
    on_called do
    end
  end

  method "shared" do
    title "Define a shared definition"
    on_called do |id, &block|
      JABA.context.register_shared(id, block)
    end
  end

  # Top level attributes

  attr "buildsystem", type: :choice do
    title "Target build system"
    items [:vs2019, :vs2022]
    default :vs2022
  end

  attr "platform", type: :choice do
    title "Target platform"
    items [:windows]
    default :windows
  end

  attr "arch", type: :choice do
    title "target architecture"
    items [:x86, :x86_64]
    default :x86_64
  end

  attr "artefact_root", type: :dir do
    title "Root of build artefacts the build system generates"
    flags :no_check_exist
    default do
      "#{buildsystem_root}/artefact"
    end
  end

  attr "buildsystem_root", type: :dir do
    title "Root of generated build system"
    flags :no_check_exist
    default do
      "buildsystem/#{buildsystem}"
    end
  end

  attr "vcfiletype", variant: :hash, type: :string do
    title "Visual C++ file types"
    key_type :ext
    default({
      ".h" => :ClInclude,
      ".inl" => :ClInclude,
      ".hpp" => :ClInclude,
      ".cpp" => :ClCompile,
      ".c" => :ClCompile,
      ".cxx" => :ClCompile,
      ".cc" => :ClCompile,
      ".png" => :Image,
      ".asm" => :MASM,
      ".rc" => :ResourceCompile,
      ".natvis" => :Natvis,
    })
  end

  # Global attributes. Available in all nodes but not at top level.

  attr "*/id", type: :string do
    title "TODO"
    flags :node_option
  end

  attr "*/root", type: :dir do
    title "TODO"
    flags :node_option
  end

  # Target node

  node "target" do
    title "Define a target"
    note "Split into 'target' level attributes and 'config' level attributes"
  end

  # Target level attributes, all flagged with :per_target

  attr "target/configs", variant: :array, type: :string do
    title "Build configurations"
    flags :per_target, :overwrite_default
    default [:Debug, :Release]
    example "configs [:debug, :release]"
  end

  attr "target/deps", variant: :array, type: :string do
    title "Target dependencies"
    note 'List of ids of other cpp definitions. When a dependency is specified all the dependency\'s exports ' \
         'will be imported, the library will be linked to and a project level dependency created (unless :soft specified). ' \
         'To prevent linking specify :nolink - useful if only headers are required. A hard dependency is the default.' \
         'This can be used for \'header only\' dependencies'
    flags :per_target
    flag_options :hard, :soft, :nolink
    example %Q{
      target :MyApp do
        type :app
        ...
        deps [:MyLib]
        deps [:MyLib2], :soft # No hard project dependency so not required in workspace
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

  attr "target/projdir", type: :dir do
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

  attr "target/projname", type: :basename do
    title "Base name of project files"
    note "Defaults to $(id)$(projsuffix)"
    flags :per_target
    default do
      "#{id}#{projsuffix}"
    end
  end

  attr "target/projsuffix", type: :string do
    title "Optional suffix to be applied to $(projname)"
    note "Has no effect if $(projname) is set explicitly"
    flags :per_target
  end

  # Config level attributes

  attr "target/config", type: :string do
    title "Current target config as an id"
    note "Returns current config being processed. Use to define control flow to set config-specific atttributes"
    flags :per_config, :read_only
    # TODO: examples, including regexes
  end

  attr "target/configname", type: :string do
    title "Display name of config as seen in IDE"
    flags :per_config
    default do
      config.capitalize_first
    end
  end

  attr "target/cpplang", type: :choice do
    title "C++ language standard"
    flags :per_config
    items ["C++11", "C++14", "C++17", "C++20", "C++23"]
    default "C++14"
  end

  attr "target/bindir", type: :dir do
    title "Output directory for executables"
    flags :per_config, :no_check_exist
    base_attr :artefact_root
    default do
      "#{arch}/bin/#{config}"
    end
  end

  attr "target/libdir", type: :dir do
    title "Output directory for libs"
    flags :per_config, :no_check_exist
    base_attr :artefact_root
    default do
      "#{arch}/lib/#{config}"
    end
  end

  attr "target/objdir", type: :dir do
    title "Output directory for object files"
    flags :per_config, :no_check_exist
    base_attr :artefact_root
    default do
      "#{arch}/obj/#{config}/#{projname}"
    end
    note "Defaults to $(arch)/obj/$(config)/$(projname)"
  end

  attr "target/debug", type: :bool do
    title "Flags config as a debug config"
    note 'Defaults to true if config id contains \'debug\''
    flags :per_config
    default do
      config =~ /debug/i ? true : false
    end
  end

  attr "target/charset", type: :choice do
    title "Character set"
    items [
      :ascii,
      :mbcs,    # Visual Studio only
      :unicode,
    ]
    default :unicode
    flags :per_config
    example "charset :unicode"
  end

  attr "target/cflags", variant: :array, type: :string do
    title "Raw compiler command line switches"
    flags :per_config, :exportable
  end

  attr "target/lflags", variant: :array, type: :string do
    title "Raw linker command line switches"
    flags :per_config, :exportable
  end

  attr "target/define", variant: :array, type: :string do
    title "Preprocessor defines"
    flags :per_config, :exportable
  end

  attr "target/inc", variant: :array, type: :dir do
    title "Include paths"
    base_attr :root
    flags :per_config, :no_sort, :exportable
    example "inc ['mylibrary/include']"
    example "inc ['mylibrary/include'], :export # Export include path to dependents"
  end

  attr "target/exceptions", type: :choice do
    title "Enables C++ exceptions"
    flags :per_config
    items [true, false]
    items [:structured] # Windows only
    default true
    example "exceptions false # disable exceptions"
  end

  attr "target/rtti", type: :bool do
    title "Enables runtime type information"
    flags :per_config
    example "rtti true"
  end

  attr "target/rule", variant: :array, type: :compound do
    title "TODO"
    flags :per_config
  end

  attr "target/rule/input", variant: :array, type: :src do
    title "TODO"
    base_attr :root
  end

  # TODO: shouldn't this be array?
  attr "target/rule/implicit_input", type: :file do
    title "Implicit input files"
    base_attr :root
  end

  # TODO: shouldn't this be array?
  attr "target/rule/output", type: :file do
    title "Output files"
    base_attr :root
    flags :required, :no_check_exist
  end

  attr "target/rule/cmd", type: :string do
    title "Command line to execute"
    flags :required
    flag_options :absolute
    note "Use :absolute to make usage of $(input) or $(output) in the command line use absolute paths. " \
         "Otherwise they will be relative to the generated project."
  end

  attr "target/rule/msg", type: :string do
    title "Message"
    note "Message that will be echoed to console on execution of the rule."
    note "Certain characters like < > | & are automatically escaped to prevent unwanted side effects such as writing text to a file - " \
         "this is a common reason why Visual Studio users are sometimes baffled as to why their custom build tool messages are not being printed."
  end

  attr "target/src", variant: :array, type: :src do
    title "Source file specification"
    base_attr :root
    flags :per_config, :exportable
    flags :no_sort # sorted at project generation time
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
    }
  end

  attr "target/src_ext", variant: :array, type: :ext do
    title "File extensions used when matching src files"
    note "Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes."
    flags :per_config, :no_sort, :exportable
    default do
      ext = [".cpp", ".h", ".inl", ".c", ".cc", ".cxx", ".hpp"]
      #ext.concat(host.cpp_src_ext) # TODO
      #ext.concat(platform.cpp_src_ext) # TODO
      ext
    end
  end

  attr "target/libs", variant: :array, type: :file do
    title 'Paths to required non-system libs'
    base_attr :root
    flags :per_config, :no_sort, :no_check_exist, :exportable
  end

  attr "target/syslibs", variant: :array, type: :string do
    title 'System libs'
    flags :per_config, :no_sort, :exportable
  end

  attr "target/targetname", type: :basename do
    title "Base name of output file without extension"
    note "Defaults to $(targetprefix)$(projname)$(targetsuffix)"
    flags :per_config
    default do
      "#{targetprefix}#{projname}#{targetsuffix}"
    end
  end

  attr "target/targetprefix", type: :string do
    title "Prefix to apply to $(targetname)"
    note "Has no effect if $(targetname) specified"
    flags :per_config
  end

  attr "target/targetsuffix", type: :string do
    title "Suffix to apply to $(targetname)"
    note "Has no effect if $(targetname) specified"
    flags :per_config
  end

  attr "target/targetext", type: :ext do
    title "Extension to apply to $(targetname)"
    note "Defaults to standard extension for $(type) of project for target $(platform)"
    flags :per_config
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

  attr "target/type", type: :choice do
    title "Target type"
    items [:app, :console, :lib, :dll, :virtual]
    flags :per_config
    default :app
  end

  attr "target/warnerror", type: :bool do
    title "Enable warnings as errors"
    flags :per_config
    example "warnerror true"
  end

  # VisualC per-target attributes

  attr "target/vcguid", type: :uuid do
    title "Globally unique id (GUID)"
    note "Seeded by $(projname). Required by Visual Studio project files"
    flags :per_target
    default do
      projname
    end
  end

  attr "target/vcglobal", variant: :hash, type: :to_s do
    title "Address Globals property group in a vcxproj directly"
    key_type :string
    value_option :condition
    flags :per_target, :exportable
  end

  attr "target/vc_extension_settings", variant: :hash, type: :file do
    title "Path to a .props file"
    key_type :ext
    flags :per_target
    base_attr :root
  end

  attr "target/vc_extension_targets", variant: :hash, type: :file do
    title "Path to a .targets file"
    key_type :ext
    flags :per_target
    base_attr :root
  end

  attr "target/winsdkver", type: :choice do
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

  attr "target/vcimportlib", type: :file do
    title "Name of import lib for use will dlls"
    flags :per_config, :no_check_exist
    note "Defaults to $(projname)$(targetsuffix).lib"
    default do
      "#{projname}#{targetsuffix}.lib"
    end
    base_attr :libdir
  end

  attr "target/vcwarnlevel", type: :choice do
    title "Visual Studio warning level"
    flags :per_config
    items [1, 2, 3, 4]
    default 3
  end

  attr "target/vcnowarn", variant: :array, type: :int do
    title "Warnings to disable"
    flags :per_config
    flags :exportable
    example "vcnowarn [4100, 4127, 4244]"
  end

  attr "target/vcfprop", variant: :hash, type: :to_s do
    title "Add per-configuration per-file property"
    key_type :string
    flags :per_config, :exportable
    validate_key do |key|
      if key !~ /^[^|]+\|{1}[A-Za-z0-9_-]+/
        fail "Must be of form <src file>|<property> but was '#{key}'"
      end
    end
    example %Q{
      # Set a property on win32/file.c
      vcfprop "win32/file.c|ObjectFileName", "$(IntDir)win32_file.obj"

      # Set same property on all matching files
      vcfprop "win32/*|DisableSpecificWarnings", 4096
    }
  end

  attr "target/vcprop", variant: :hash, type: :to_s do
    title "Address per-configuration sections of a vcxproj directly"
    key_type :string
    value_option :condition
    flags :per_config, :exportable
    validate_key do |key|
      if key !~ /^[A-Za-z0-9_-]+\|{1}[A-Za-z0-9_-]+/
        fail "Must be of form <group>|<property> but was '#{key}'"
      end
    end
  end

  attr "target/vctoolset", type: :choice do
    title "Toolset version to use"
    note "Defaults to host's default toolset"
    flags :per_config
    items ["v100", "v110", "v120", "v140", "v141", "v142", "v143"]
    default do
      "v143" # TODO
      #host.toolset
    end
  end
end
