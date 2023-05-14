JABA.define_api(:attr_types) do
  attr_type :null do
    title "Null attribute type"
  end

  attr_type :string do
    title "String attribute type"
  end

  attr_type :bool do
    title "Boolean attribute type"
  end

  attr_type :choice do
    title "Choice attribute type"
    note "Can take exactly one of a set of unique values"
  end

  attr_type :uuid do
    title "UUID attribute type"
  end

  attr_type :file do
    title "File attribute type"
    note "Validates that value is a string path representing a file"
    # TODO: document basedir_spec
  end

  attr_type :dir do
    title "Directory attribute type"
    note "Validates that value is a string path representing a directory"
  end

  attr_type :basename do
    title "basename attribute type"
    note "Basename of a file. Slashes are rejected."
  end

  attr_type :src do
    title "Source file specification pattern"
    note "Can be file glob match an explicit path or a directory"
  end

  attr_type :compound do
    title "Compound attribute type"
  end
end

JABA.define_api(:core) do
  # Flags

  flag :allow_dupes do
    title "Array duplicates strategy"
    note "Allows array attributes to contain duplicates. If not specified duplicates are stripped"
    compatible? do |attr_def|
      if !attr_def.array?
        definition_error("only allowed on array attributes")
      end
    end
  end

  flag :exportable do
    title "Attribute is exportable"
    note "Flags an attribute as being able to be exported to dependents. Only array and hash attributes can be flagged with this."
    compatible? do |attr_def|
      if !attr_def.array? && !attr_def.hash?
        definition_error("only allowed on array/hash attributes")
      end
    end
    init_attr_def do |attr_def|
      attr_def.set_flag_options(:export, :export_only)
    end
  end

  flag :no_sort do
    title "Do not sort array attributes"
    note "Allows array attributes to remain in the order they are set in. If not specified arrays are sorted"
    compatible? do |attr_def|
      if !attr_def.array?
        definition_error("only allowed on array attributes")
      end
    end
  end

  flag :node_option do
    title "Flags the attribute as being callable as an option passed into a definition"
    example %Q{
  target :my_app, root: "my_root" do # 'root' attr is flagged with :node_option
    ...
  end
    }
  end

  flag :overwrite_default do
    title "If set default is overwritten if set by user else default is extended"
    compatible? do |attr_def|
      if attr_def.single?
        definition_error("only allowed on array and hash attributes")
      end
    end
  end

  flag :per_target do
    title "Flags attributes inside the target namespace as being per-target rather than per-config"
  end

  flag :per_config do
    title "Flags attributes inside the target namespace as being per-config rather than per-target"
  end

  flag :read_only do
    title "Prevents user from writing to value"
    note "Specifies that the attribute can only be read and not set from user definitions. The value will be initialised inside Jaba"
  end

  flag :required do
    title "Force user to supply a value"
    note "Specifies that the definition writer must supply a value for this attribute"
    compatible? do |attr_def|
      if attr_def.default_set?
        definition_error("can only be specified if no default specified")
      end
    end
  end

  # basedir_specs

  basedir_spec :jaba_file do
    title "path will be based on the directory of the jaba file the definition is in"
    note "If $(root) attribute is set that will take precedence and override this. The root attribute is itself" \
         "specified relative to the jaba file."
    note "Another caveat is that if an attribute flagged with :jaba_file is set in a shared definition " \
         "it will base itself off the root definition that included the shared definition"
  end

  basedir_spec :definition_root do
    title "path will be based on $(root) attribute"
  end

  basedir_spec :build_root do
    title "path will be based on build_root"
  end

  basedir_spec :buildsystem_root do
    title "path will be based on buildsystem (itself based on build_root)"
  end

  basedir_spec :artefact_root do
    title "path will be based on build artefact root"
  end

  # Global methods

  global_method "available" do
    title "Array of attributes/methods available in current scope"
  end

  global_method "print" do
    title "Prints a non-newline terminated string to stdout"
    on_called do |str| Kernel.print(str) end
  end

  global_method "puts" do
    title "Prints a newline terminated string to stdout"
    on_called do |str| Kernel.puts(str) end
  end

  global_method "fail" do
    title "Raise an error"
    note "Stops execution"
    on_called do |msg| JABA.error(msg, line: $last_call_location) end
  end

  method "*/include" do
    title "Include a shared definition"
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
end

JABA.define_api(:target) do
  # Global attributes. Available in all nodes but not at top level.

  attr "*/root", type: :dir do
    title "TODO"
    flags :node_option
    basedir_spec :jaba_file
  end

  # Top level attributes


  # Target node

  node "target" do
    title "Define a target"
  end

  attr_array "target/configs", type: :string do
    title 'Build configurations'
    flags :per_target, :required, :no_sort, :exportable
    example 'configs [:debug, :release]'
  end

  attr "target/config", type: :string do
    title "Current target config as an id"
    note "Returns current config being processed. Use to define control flow to set config-specific atttributes"
    flags :per_config, :read_only
    # TODO: examples, including regexes
  end

  attr_array "target/define", type: :string do
    title "Preprocessor defines"
    flags :per_config, :exportable
  end

  attr_array "target/inc", type: :dir do
    title 'Include paths'
    basedir_spec :definition_root
    flags :no_sort, :exportable
    example "inc ['mylibrary/include']"
    example "inc ['mylibrary/include'], :export # Export include path to dependents"
  end

  attr "target/projdir", type: :dir do
    title 'Directory in which projects will be generated'
    #flags :no_check_exist # May get created during generation # TODO
    basedir_spec :buildsystem_root
    example %Q{
      cpp :MyApp do
        src ['**/*'] # Get all src in $(root), which defaults to directory of definition file
        projdir 'projects' # Place generated projects in 'projects' directory
      end
    }
  end

  attr "target/projname", type: :basename do
    title 'Base name of project files'
    note 'Defaults to $(id)$(projsuffix)'
    default "#{id}#{projsuffix}"
  end

  attr "target/projsuffix", type: :string do
    title 'Optional suffix to be applied to $(projname)'
    note 'Has no effect if $(projname) is set explicitly'
  end

  attr "target/rule", type: :compound do
    title "TODO"
    flags :per_config
  end

  attr "target/rule/input", type: :src do
    title "TODO"
    basedir_spec :definition_root
  end

  attr_array "target/src", type: :src do
    title 'Source file specification'
    basedir_spec :definition_root
    flags :per_config
    #flags :required # Must be specified by user
    #flags :no_sort # Final source will be sorted so no need to sort this
    flags :exportable
    flag_options :force # Specify when explicitly specified src does not exist on disk but still want to add to project
    value_option :vpath # For organising files in a generated project
    # TODO: examples for excludes
    example %Q{
      # Add all src in $(root) whose extension is in $(src_ext)
      src ['*']

      # Add all src in $(root)/src whose extension is in $(src_ext), recursively
      src ['src/**/*']

      # Glob matches are not required to add whole directory recursively (whose extension is in $(src_ext))
      src ['src']

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

  attr_array "target/src_ext", type: :string do
    title 'File extensions used when matching src files'
    note 'Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes.'
    flags :no_sort, :exportable
    default do
      ext = ['.cpp', '.h', '.inl', '.c', '.cc', '.cxx', '.hpp']
      #ext.concat(host.cpp_src_ext) # TODO
      #ext.concat(platform.cpp_src_ext) # TODO
      ext
    end
  end

  attr "target/type", type: :choice do
    title "Target type"
    items [:app, :console, :lib, :dll]
    flags :per_config
    default :app
  end
end
