JDL.flag :required do
  title "Force user to supply a value"
  note "Specifies that the definition writer must supply a value for this attribute"
  compatible? do |attr_def|
    if attr_def.default_set?
      JABA.error("#{describe} can only be specified if no default specified")
    end
  end
end

JDL.flag :read_only do
  title "Prevents user from writing to value"
  note "Specifies that the attribute can only be read and not set from user definitions. The value will be initialised inside Jaba"
end

JDL.flag :allow_dupes do
  title "Array duplicates strategy"
  note "Allows array attributes to contain duplicates. If not specified duplicates are stripped"
  compatible? do |attr_def|
    if !attr_def.array?
      JABA.error("#{describe} is only allowed on array attributes")
    end
  end
end

JDL.method "print", scope: :global do
  title "Prints a non-newline terminated string to stdout"
  on_called do |str| Kernel.print(str) end
end

JDL.method "puts", scope: :global do
  title "Prints a newline terminated string to stdout"
  on_called do |str| Kernel.puts(str) end
end

JDL.method "fail", scope: :global do
  title "Raise an error"
  note "Stops execution"
  on_called do |msg| JABA.error(msg, want_backtrace: false) end
end

JDL.method "shared", scope: :top_level do
  title "Define a shared definition"
  on_called do end
end

# have made decision that the contents of project will be 'configs'
# eg
# configs [:debug, :release] - default configs defined at top level scope
# target_platform :win32  - target_platform(s) defined at top level scope

# project :myproj, root: "myroot", configs: [:mydebug, :myrelease] do
#  type :lib # can have a different type per config
#  src ['*'] # src now on a per-config basis
#  inc ['.']
#  ...
# end
JDL.node "project" do
  title "Define a project"
end

# TODO: flag this as being an option on project
# eg project :myproj, root: "myroot"
JDL.attr "project|root" do #, type: :string do
  title "TODO"
  flags []
end

JDL.node "project|rule" do
  title "TODO"
end

JDL.attr "project|rule|input" do #, type: :src_spec do
  title "TODO"
end

JDL.method "include", scope: ["project"] do
  title "Include a shared definition"
  on_called do |id|
    JABA.context.include_shared(id)
  end
end

JDL.method "glob", scope: :top_level do
  title "glob files"
  on_called do
  end
end
