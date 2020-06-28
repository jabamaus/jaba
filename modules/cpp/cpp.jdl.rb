# frozen_string_literal: true

define :cpp do

  title 'Cross platform C++ project definition'

   attr_array :hosts, type: :choice do
    title 'Target hosts'
    note "The following hosts are available as standard: #{all_instance_ids(:host).join(', ')}"
    items all_instance_ids(:host)
    flags :required
  end
  
  attr :root, type: :dir do
    title 'Root directory relative to which all other paths are specified'
    note 'Root of the project specified as an offset from the file that contains the project definition. ' \
         'All paths are specified relative to this. Project files will be generated here unless $(projroot) is set. ' \
         'Path can also be absolute but explicitly specified absolute paths should be avoided in definitions where possible ' \
         'in order to not damage portability'
    default '.'
  end

  define :per_host do

    # Required attributes that the user must provide a value for.
    #
    attr_array :platforms, type: :choice do
      title 'Target platforms'
      items all_instance_ids(:platform) # TODO: should only allow platforms supported by this host
      flags :required
      example "platforms [:windows]"
      example "platforms [:macos, :ios]"
    end
    
    # Control flow attributes
    #
    attr :host, type: :symbol do
      title 'Target host as an id'
      note 'Query current target host'
      flags :read_only
      example %q{
        case host
        when :vs2019
          ...
        when :xcode
          ...
        end
      }
    end

    attr :host_ref, type: :reference do
      title 'Target host as object'
      note 'Use when access to host attributes is required'
      referenced_type :host
    end

  end

  define :project do

    # Required attributes that the user must provide a value for.
    #
    attr_array :archs, type: :choice  do
      title 'Target architectures'
      items all_instance_ids(:arch) # TODO: should be valid_archs for current platform
      flags :required
      example 'archs [:x86, :x86_64]'
    end

    attr_array :configs, type: :symbol_or_string do
      title 'Build configurations'
      flags :required, :nosort
      flag_options :export
      example 'configs [:Debug, :Release]'
    end

    # Control flow attributes
    #
    attr :platform, type: :symbol do
      title 'Target platform as an id'
      note 'Query current target platform'
      flags :read_only
      example %Q{
        case platform
        when :windows
          ...
        when :macos
          ...
        end
      }
    end
      
    attr :platform_ref, type: :reference do
      title 'Target platform as an object'
      note 'Use when access to platform attributes is required'
      referenced_type :platform
    end
  
    # Common attributes
    #
    attr_array :deps, type: :reference do
      title 'Project dependencies'
      note 'List of ids of other cpp definitions'
      referenced_type :cpp
      make_handle do |id|
        "#{id}|#{host}|#{platform}"
      end
      example %Q{
        cpp :MyApp do
          type :app
          ...
          deps [:MyLib]
        end
        
        cpp :MyLib do
          type :lib
          ...
        end
      }
    end

    attr :projroot, type: :dir do
      title 'Directory in which projects will be generated'
      default '.'
      flags :no_check_exist # May get created during generation
      note 'Specified as an offset from $(root). If not specified projects will be generated in $(root)'
      note 'Path can also be absolute but explicitly specified absolute paths should be avoided in definitions where possible ' \
            'in order to not damage portability'
      example %Q{
        cpp :MyApp do
          src ['**/*'] # Get all src in $(root), which defaults to directory of definition file
          projroot 'projects' # Place generated projects in 'projects' directory
        end
      }
    end
    
    attr :projname, type: :string do
      title 'Base name of project files'
      note 'Defaults to $(id)$(projsuffix)'
      default do
        "#{id}#{projsuffix}"
      end
    end

    attr :projsuffix, type: :string do
      title 'Optional suffix to be applied to $(projname)'
      note 'Has no effect if $(projname) is set explicitly'
    end

    attr_array :src, type: :src_spec do
      title 'Source file specification'
      flags :required # Must be specified by user
      flags :nosort # Final source will be sorted so no need to sort this
      flag_options :force # Specify when explicitly specidied src does not exist on disk but still want to add to project
      flag_options :export
      value_option :vpath # For organising files in a generated project
      # TODO: examples for excludes
      # TODO: add absolute path example
      example "src ['*']  # Add all src in $(root) whose extension is in $(src_ext)"
      example "src ['src/**/*'] # Add all src in $(root)/src whose extension is in $(src_ext), recursively"
      example "src ['main.c', 'io.c'] # Add src explicitly"
      example "src ['jaba.jdl.rb']  # Explicitly add even though not in $(src_ext)"
      example "src ['does_not_exist.cpp'], :force  # Force addition of file not on disk"
    end
    
    attr_array :src_ext do
      title 'File extensions used when matching src files'
      note 'Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes.'
      flags :nosort
      flag_options :export
      default do
        ext = ['.cpp', '.h', '.inl', '.c', '.cc', '.cxx', '.hpp']
        if visual_studio?
          ext << '.natvis'
        elsif xcode?
          ext << '.xcconfig'
        end
        case platform
        when :windows
          ext << '.def' << '.rc'
        end
        ext
      end
    end

  end

  define :per_arch do

    attr :arch, type: :symbol_or_string do
      title 'Target architecture as an id'
      note 'Query current architecture being processed. Use to define control flow to set config-specific atttributes'
      flags :read_only
    end

    attr :arch_ref, type: :reference do
      title 'Target architecture as an object'
      referenced_type :arch
    end

  end

  # Sub-grouping of attributes that pertain to a build configuration
  #
  define :config do

    # Required attributes that the user must provide a value for.
    #
    attr :type, type: :choice do
      title 'Project type'
      items [:app, :console, :lib, :dll]
      flags :required
    end

    # Control flow attributes
    #
    attr :config, type: :symbol_or_string do
      title 'Current target config as an id'
      note 'Returns current config being processed. Use to define control flow to set config-specific atttributes'
      flags :read_only
      # TODO: examples, including regexes
    end

    # Common attributes. These are the attributes that most definitions will set/use.
    #
    attr_array :build_action, type: :string do
      title 'Build action'
      flag_options :export
      value_option :msg
      value_option :type, required: true, items: [:PreBuild, :PreLink, :PostBuild]
    end

    attr :buildroot, type: :dir do
      title 'Root directory for build artifacts'
      note 'Specified as a relative path from $(root)'
      default 'build'
      flags :no_check_exist
    end

    attr :bindir, type: :dir do
      default do
        "#{buildroot}/bin/#{config}"
      end
      flags :no_check_exist
    end

    attr :libdir, type: :dir do
      default do
        "#{buildroot}/lib/#{config}"
      end
      flags :no_check_exist
    end

    attr :objdir, type: :dir do
      default do
        "#{buildroot}/obj/#{config}/#{projname}"
      end
      flags :no_check_exist
    end

    attr_array :cflags do
      title 'Raw compiler command line switches'
      flag_options :export
    end

    attr :configname do
      note 'Display name of config in Visual Studio. Defaults to $(config)'
      default do
        config
      end
    end

    attr :debug, type: :bool do
      note 'Flags config as a debug build. Defaults to true if config id contains \'debug\''
      default do
        config =~ /debug/i ? true : false
      end
    end
    
    attr_array :defines, type: :symbol_or_string do
      title 'Preprocessor defines'
      flag_options :export
    end

    attr_array :inc, type: :dir do
      title 'Include paths'
      flags :nosort
      flag_options :export
      example "inc ['mylibrary/include']"
      example "inc ['mylibrary/include'], :export # Export include path to dependents"
    end

    attr_array :nowarn do
      title 'Warnings to disable'
      note 'Placed directly into projects as is, with no validation'
      flag_options :export
      example "nowarn [4100, 4127, 4244] if visual_studio?"
    end

    attr :targetname, type: :string do
      title 'Base name of output file without extension'
      note 'Defaults to $(targetprefix)$(projname)$(targetsuffix)'
      default do
        "#{targetprefix}#{projname}#{targetsuffix}"
      end
    end
    
    attr :targetprefix, type: :string do
      title 'Prefix to apply to $(targetname)'
      note 'Has no effect if $(targetname) specified'
    end
    
    attr :targetsuffix, type: :string do
      title 'Suffix to apply to $(targetname)'
      note 'Has no effect if $(targetname) specified'
    end

    attr :targetext, type: :string do
      title 'Extension to apply to $(targetname)'
      note 'Defaults to standard extension for $(type) of project for target $(platform)'
      default do
        case platform
        when :windows
          case type
          when :app, :console
            '.exe'
          when :lib
            '.lib'
          when :dll
            '.dll'
          end
        when :ios
          case type
          when :app, :console
            '.app'
          when :lib
            '.a'
          end
        end
      end
    end

    attr :warnerror, type: :bool do
      title 'Enable warnings as errors'
      example 'warnerror true'
    end

    # Not so common attributes. Often used but not fundamental.
    #
    attr :character_set, type: :choice do
      note 'Character set. Defaults to :unicode'
      items [
        :mbcs,    # Visual Studio only
        :unicode,
        nil
      ]
      default nil
      example 'character_set :unicode'
    end

    attr :exceptions, type: :choice do
      title 'Enables C++ exceptions'
      items [true, false]
      items [:structured] # Windows only
      default true
      example 'exceptions false # disable exceptions'
    end

    attr :rtti, type: :bool do
      title 'Enables runtime type information'
      default true
      example 'rtti false # Disable rtti'
    end

    attr :toolset, type: :string do
      default { host_ref.toolset }
    end

  end

end

# Each host (eg Visual Studio, Xcode etc) must provide a class name which will be used in project
# creation. If plugging in a new cpp host generator then a new subclass of 'Project' should be
# implemented.
#
open_type :host do
  attr :cpp_project_classname do
    flags :required
  end
end
