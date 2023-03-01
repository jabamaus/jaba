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

JDL.node "app" do
  title "Define an app"
end

JDL.node "lib" do
  title "Define a lib"
end

JDL.node "app|config" do
  title "TODO"
end

JDL.node "app|config|rule" do
  title "TODO"
end

JDL.attr "app|config|rule|input" do #, type: :src_spec do
  title "TODO"
end

JDL.method "include", scope: ["app", "lib"] do
  title "Include a shared definition"
  on_called do |id|
    JABA.context.include_shared(id)
  end
end

JDL.attr "app|root", "lib|root" do #, type: :string do
  title "TODO"
  flags []
end

JDL.method "glob", scope: :top_level do
  title "glob files"
  on_called do
  end
end
