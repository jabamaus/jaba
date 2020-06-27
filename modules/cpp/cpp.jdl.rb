# frozen_string_literal: true

define :cpp do

  title 'Cross platform C++ project definition'

   attr_array :hosts, type: :choice do
    title 'Target hosts'
    help "The following hosts are available as standard: #{all_instance_ids(:host).join(', ')}"
    items all_instance_ids(:host)
    flags :required
  end
  
  attr :root, type: :dir do
    title 'Root directory relative to which all other paths are specified'
    help 'Root of the project specified as a relative path to the file that contains the project definition. ' \
         'All paths are specified relative to this. Project files will be generated here unless <projroot> is set.'
    default '.'
  end

  define :per_host do

    # Required attributes that the user must provide a value for.
    #
    attr_array :platforms, type: :choice do
      items all_instance_ids(:platform) # TODO: should only allow platforms supported by this host
      flags :required
    end
    
    # Control flow attributes
    #
    attr :host, type: :symbol do
      flags :read_only
    end

    attr :host_ref, type: :reference do
      referenced_type :host
    end

  end

  define :project do

    # Required attributes that the user must provide a value for.
    #
    attr_array :archs, type: :choice  do
      items all_instance_ids(:arch) # TODO: should be valid_archs for current platform
      flags :required
    end

    attr_array :configs, type: :symbol_or_string do
      flags :required, :nosort
      flag_options :export
    end

    # Control flow attributes
    #
    attr :platform, type: :symbol do
      title 'Target platform'
      help 'Use for querying the current target platform'
      flags :read_only
    end
      
    attr :platform_ref, type: :reference do
      title 'Target platform node'
      help 'Use when access to platform attributes is required'
      referenced_type :platform
    end
  
    # Common attributes
    #
    attr_array :deps, type: :reference do
      help 'Specify project dependencies. List of ids of other cpp definitions.'
      referenced_type :cpp
      make_handle do |id|
        "#{id}|#{host}|#{platform}"
      end
    end

    attr :projroot, type: :dir do
      help 'Directory in which projects will be generated. Specified as a relative path from <root>. If not specified ' \
      'projects will be generated in <root>'
      default '.'
      flags :no_check_exist # May get created during generation
    end
    
    attr :projname, type: :string do
      title 'Base name of project files'
      help 'Defaults to <id><projsuffix>.'
      default { "#{id}#{projsuffix}" }
    end

    attr :projsuffix, type: :string do
      help 'Optional suffix to be applied to <projname>. Has no effect if <projname> is set explicitly.'
    end

    attr_array :src, type: :src_spec do
      title 'Source file specification'
      flags :required # Must be specified by user
      flags :nosort # Final source will be sorted so no need to sort this
      flag_options :force # Specify when explicitly specidied src does not exist on disk but still want to add to project
      flag_options :export
      value_option :vpath # For organising files in a generated project
      example "src ['*']  # Add all src in <root> whose extension is in <src_ext>"
      example "src ['jaba.jdl.rb']  # Explicitly add even though not in <src_ext>"
      example "src ['does_not_exist.cpp'], :force  # Force addition of file not on disk"
    end
    
    attr_array :src_ext do
      help 'File extensions that will be added when src is not specified explicitly. ' \
           'Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes.'
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
      help 'Returns current arch being processed. Use to define control flow to set config-specific atttributes'
      flags :read_only
    end

    attr :arch_ref, type: :reference do
      referenced_type :arch
    end

  end

  # Sub-grouping of attributes that pertain to a build configuration
  #
  define :config do

    # Required attributes that the user must provide a value for.
    #
    attr :type, type: :choice do
      items [:app, :console, :lib, :dll]
      flags :required
    end

    # Control flow attributes
    #
    attr :config, type: :symbol_or_string do
      help 'Returns current config being processed. Use to define control flow to set config-specific atttributes'
      flags :read_only
    end

    # Common attributes. These are the attributes that most definitions will set/use.
    #
    attr_array :build_action, type: :string do
      help 'Build action, eg a prebuild step'
      flag_options :export
      value_option :msg
      value_option :type, required: true, items: [:PreBuild, :PreLink, :PostBuild]
    end

    attr :buildroot, type: :dir do
      title 'Root directory for build artifacts'
      help 'Specified as a relative path from <root>'
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
      help 'Raw compiler command line switches'
      flag_options :export
    end

    attr :configname do
      help 'Display name of config in Visual Studio. Defaults to <config>'
      default { config }
    end

    attr :debug, type: :bool do
      help 'Flags config as a debug build. Defaults to true if config id contains \'debug\''
      default do
        config =~ /debug/i ? true : false
      end
    end
    
    attr_array :defines, type: :symbol_or_string do
      help 'Preprocessor defines'
      flag_options :export
    end

    attr_array :inc, type: :dir do
      help 'Include paths'
      flags :nosort
      flag_options :export
    end

    attr_array :nowarn do
      title 'Warnings to disable'
      help 'Placed directly into projects as is, with no validation'
      flag_options :export
    end

    attr :targetname, type: :string do
      title 'Base name of output file without extension'
      help 'Defaults to <targetprefix><targetname><projname><targetsuffix>'
      default { "#{targetprefix}#{projname}#{targetsuffix}" }
    end
    
    attr :targetprefix, type: :string do
      title 'Prefix to apply to <targetname>'
      help 'Has no effect if <targetname> specified'
    end
    
    attr :targetsuffix, type: :string do
      title 'Suffix to apply to <targetname>'
      help 'Has no effect if <targetname> specified'
    end

    attr :targetext, type: :string do
      title 'Extension to apply to <targetname>'
      help 'Defaults to standard extension for <type> of project for target <platform>'
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
      help 'Enable warnings as errors. Off by default.'
    end

    # Not so common attributes. Often used but not fundamental.
    #
    attr :character_set, type: :choice do
      help 'Character set. Defaults to :unicode'
      items [
        :mbcs,    # Visual Studio only
        :unicode,
        nil
      ]
      default nil
    end

    attr :exceptions, type: :choice do
      help 'Enables C++ exceptions. On by default.'
      items [true, false]
      items [:structured] # Windows only
      default true
    end

    attr :rtti, type: :bool do
      help 'Enable runtime type information. On by default.'
      default true
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
