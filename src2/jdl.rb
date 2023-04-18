# Flags

JDL.flag :allow_dupes do
  title "Array duplicates strategy"
  note "Allows array attributes to contain duplicates. If not specified duplicates are stripped"
  compatible? do |attr_def|
    if !attr_def.array?
      definition_error("only allowed on array attributes")
    end
  end
end

JDL.flag :no_sort do
  title "Do not sort array attributes"
  note "Allows array attributes to remain in the order they are set in. If not specified arrays are sorted"
  compatible? do |attr_def|
    if !attr_def.array?
      definition_error("only allowed on array attributes")
    end
  end
end

JDL.flag :node_option do
  title "Flags the attribute as being callable as an option passed into a definition"
  example %Q{
project :my_project, root: "my_root" do # 'root' attr is flagged with :node_option
  ...
end
  }
end

JDL.flag :per_project do
  title "Flags attributes inside the Project namespace as being per-project rather than per-config"
end

JDL.flag :per_config do
  title "Flags attributes inside the Project namespace as being per-config rather than per-target"
end

JDL.flag :read_only do
  title "Prevents user from writing to value"
  note "Specifies that the attribute can only be read and not set from user definitions. The value will be initialised inside Jaba"
end

JDL.flag :required do
  title "Force user to supply a value"
  note "Specifies that the definition writer must supply a value for this attribute"
  compatible? do |attr_def|
    if attr_def.default_set?
      definition_error("can only be specified if no default specified")
    end
  end
end

# basedir_specs

JDL.basedir_spec :jaba_file do
  title "path will be based on the directory of the jaba file the definition is in"
  note "If $(root) attribute is set that will take precedence and override this. The root attribute is itself" \
       "specified relative to the jaba file."
  note "Another caveat is that if an attribute flagged with :jaba_file is set in a shared definition " \
       "it will base itself off the root definition that included the shared definition"
end

JDL.basedir_spec :build_root do
  title "path will be based on build_root"
end

JDL.basedir_spec :buildsystem_root do
  title "path will be based on buildsystem (itself based on build_root)"
end

JDL.basedir_spec :artefact_root do
  title "path will be based on build artefact root"
end

# Global methods

JDL.method "*|print" do
  title "Prints a non-newline terminated string to stdout"
  on_called do |str| Kernel.print(str) end
end

JDL.method "*|puts" do
  title "Prints a newline terminated string to stdout"
  on_called do |str| Kernel.puts(str) end
end

JDL.method "*|fail" do
  title "Raise an error"
  note "Stops execution"
  on_called do |msg| JABA.error(msg, want_backtrace: false) end
end

# Global attributes

JDL.attr "*|root", type: :dir do
  title "TODO"
  flags :node_option
end

# Top level methods

JDL.method "glob" do
  title "glob files"
  on_called do
  end
end

JDL.method "shared" do
  title "Define a shared definition"
  on_called do end
end

# Top level attributes

JDL.attr_array "configs" do
  title "Default configs"
  flags :required
end

# Project node

JDL.node "project" do
  title "Define a project"
end

JDL.attr "project|config" do #, type: :symbol_or_string do
  title "Current target config as an id"
  note "Returns current config being processed. Use to define control flow to set config-specific atttributes"
  flags :per_config, :read_only
  # TODO: examples, including regexes
end

JDL.attr_array "project|define" do #, type: :symbol_or_string do
  title "Preprocessor defines"
  #flags :exportable
end

JDL.attr "project|rule", type: :compound do
  title "TODO"
  flags :per_config
end

JDL.attr "project|rule|input", type: :src_spec do
  title "TODO"
end

JDL.attr "project|type", type: :choice do
  title "Project type"
  items [:app, :console, :lib, :dll]
  flags :per_config, :required
end

JDL.method "project|include" do
  title "Include a shared definition"
  on_called do |id|
    JABA.context.include_shared(id)
  end
end
