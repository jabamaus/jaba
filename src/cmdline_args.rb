help "Jaba build system generator v#{JABA_VERSION}"

cmd(:null, help: "") do |c|
  c.flag("--help", help: "Show help", var: :show_help)
  c.flag("--profile", help: "Profiles with ruby-prof gem", var: :profile, dev_only: true)
  c.flag("--verbose", help: "Prints extra information", var: :verbose)
end

cmd(:gen, help: "Regenerate buildsystem", default: true) do |c|
  c.value("--src-root -S", help: "Set src root", var: :src_root)
  c.key_values("--define -D", help: "Set global attribute value", var: :globals)
end

cmd(:build, help: "Execute build")
cmd(:clean, help: "Clean build")

cmd(:convert, help: "Convert .sln to jaba spec") do |c|
  c.value("--vcxproj -p", help: "Path to .vcxporj file", var: :vcxproj)
  c.value("--sln -s", help: "Path to sln file", var: :sln)
  c.value("--outdir -o", help: "Parent directory of generated .jaba file. Defaults to cwd.", var: :outdir)
end

cmd(:help, help: "Open jaba web help")
cmd(:test, help: "Run built in tests")
