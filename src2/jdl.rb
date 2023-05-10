JABA.define_api(:attr_types) do
  attr_type :null do
    title "Null attribute type"
  end

  attr_type :string do
    title "String attribute type"
  end

  attr_type :symbol do
    title "Symbol attribute type"
  end

  attr_type :symbol do
    title "Symbol attribute type"
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
  project :my_project, root: "my_root" do # 'root' attr is flagged with :node_option
    ...
  end
    }
  end

  flag :per_project do
    title "Flags attributes inside the Project namespace as being per-project rather than per-config"
  end

  flag :per_config do
    title "Flags attributes inside the Project namespace as being per-config rather than per-target"
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

JABA.define_api(:project) do
  # Global attributes. Available in all nodes but not at top level.

  attr "*/root", type: :dir do
    title "TODO"
    flags :node_option
    basedir_spec :jaba_file
  end

  # Top level attributes


  # Project node

  node "project" do
    title "Define a project"
  end

  attr "project/config", type: :symbol do
    title "Current target config as an id"
    note "Returns current config being processed. Use to define control flow to set config-specific atttributes"
    flags :per_config, :read_only
    # TODO: examples, including regexes
  end

  attr_array "project/define", type: :string do
    title "Preprocessor defines"
    flags :per_config #, :exportable
  end

  attr "project/rule", type: :compound do
    title "TODO"
    flags :per_config
  end

  attr "project/rule/input", type: :src do
    title "TODO"
    basedir_spec :definition_root
  end

  attr "project/type", type: :choice do
    title "Project type"
    items [:app, :console, :lib, :dll]
    flags :per_config, :required
  end
end
