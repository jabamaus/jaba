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

JDL.method "puts" do
  title "Prints a line to stdout"
  on_called do |str| puts str end
end

JDL.method "shared" do
  title "Define a shared definition"
  on_called do end
end

JDL.node "app" do
  title "Define an app"
end

# TODO: need a way of registering into all APIs
JDL.method "app|fail" do
  title "Raise an error"
  on_called do |msg| JABA.error(msg, want_backtrace: false) end
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

JDL.method "app|include", "lib|include" do
  title "Include a shared definition"
  on_called do |id|
    JABA.context.include_shared(id)
  end
end

JDL.attr "app|root", "lib|root" do #, type: :string do
  title "TODO"
  flags []
end

JDL.method "glob" do
  title "glob files"
  on_called do
  end
end
