register_cmd(:null, help: "") do |c|
  c.add_flag("--help", help: "Show help", var: :show_help)
  c.add_flag("--profile", help: "Profiles with ruby-prof gem", var: :profile, dev_only: true)
  c.add_flag("--verbose", help: "Prints extra information", var: :verbose)
end

register_cmd(:gen, help: "Regenerate buildsystem", default: true) do |c|
  c.add_value("--src-root -S", help: "Set src root", var: :src_root)
  c.add_key_values("--define -D", help: "Set global attribute value", var: :globals)
end

register_cmd(:build, help: "Execute build")
register_cmd(:clean, help: "Clean build")

register_cmd(:convert, help: "Convert .sln to jaba spec") do |c|
  c.add_value("--vcxproj -p", help: "Path to .vcxporj file", var: :vcxproj)
  c.add_value("--sln -s", help: "Path to sln file", var: :sln)
  c.add_value("--outdir -o", help: "Parent directory of generated .jaba file. Defaults to cwd.", var: :outdir)
end

register_cmd(:help, help: "Open jaba web help")
