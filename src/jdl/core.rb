JDL.global_method "__dir__" do
  title "Directory of the currently executing .jaba file"
end

JDL.global_method "available" do
  title "Array of attributes/methods available in current scope"
end

JDL.global_method "clear" do
  title "Clear an array or hash attribute"
end

JDL.global_method "fail" do
  title "Raise an error"
  note "Stops execution"
  on_called do |msg| JABA.error(msg, line: $last_call_location) end
end

JDL.global_method "include" do
  title "Include a shared definition or a .jaba file"
  note "Use at file scope to include another .jaba file or inside definition blocks to include 'shared' definitions"
end

JDL.global_method "print" do
  title "Prints a non-newline terminated string to stdout"
  on_called do |str| Kernel.print(str) end
end

JDL.global_method "puts" do
  title "Prints a newline terminated string to stdout"
  on_called do |str| Kernel.puts(str) end
end

JDL.global_method "src_root" do
  title "Root directory of .jaba definitions"
  on_called do
    JABA.context.src_root_dir
  end
end

JDL.global_method "x86_64?" do
  title "Returns true if targeting x86_64"
  on_called do
    JABA.context.root_node[:arch] == :x86_64
  end
end

JDL.global_method "windows?" do
  title "Returns true if targeting windows"
  on_called do
    JABA.context.root_node[:platform] == :windows
  end
end

# Top level methods

JDL.method "glob" do
  title "Glob for files"
  on_called do
  end
end

JDL.method "shared" do
  title "Define a shared definition"
  on_called do |id, &block|
    JABA.context.register_shared(id, block)
  end
end

JDL.method "method" do
  title "Define a utility method"
  on_called do |id, &block|
    JABA.context.jdl_builder.define_top_level_method(id, &block)
  end
end

# Top level attributes

JDL.attr "buildsystem", type: "choice" do
  title "Target build system"
  items [:vs2019, :vs2022]
  default :vs2022
end

JDL.attr "platform", type: :choice do
  title "Target platform"
  items [:windows]
  default :windows
end

JDL.attr "arch", type: :choice do
  title "Target architecture"
  items [:x86, :x86_64]
  default :x86_64
end

JDL.attr "buildsystem_root", type: :dir do
  title "Root of generated build system"
  flags :no_check_exist
  default do
    "#{src_root}/buildsystem/#{buildsystem}"
  end
end

JDL.attr "artefact_root", type: :dir do
  title "Root of generated build artefacts"
  flags :no_check_exist
  default do
    "#{buildsystem_root}/artefact"
  end
end

JDL.attr "generated_src_root", type: :dir do
  title "Root location where for src files created during build"
  flags :no_check_exist
  default do
    "#{buildsystem_root}/generated_src"
  end
end

JDL.attr "defaults", variant: :array, type: :block do
  title "Set target defaults at file or global scope"
  option :scope, type: :choice do
    title "Scope"
    items [:file, :global]
  end
end

JDL.attr "src_ext", variant: :array, type: :ext do
  title "File extensions used when matching src files"
  note "Defaults to standard C/C++ file types and host/platform-specific files, but more can be added for informational purposes."
  flags :no_sort
  default do
    ext = [".cpp", ".h", ".inl", ".c", ".cc", ".cxx", ".hpp", ".jaba"]
    #ext.concat(host.cpp_src_ext) # TODO
    #ext.concat(platform.cpp_src_ext) # TODO
    ext
  end
end

JDL.attr "vcfiletype", variant: :hash, type: :string do
  title "VisualC file types"
  key_type :ext
  default({
    ".h" => :ClInclude,
    ".inl" => :ClInclude,
    ".hpp" => :ClInclude,
    ".cpp" => :ClCompile,
    ".c" => :ClCompile,
    ".cxx" => :ClCompile,
    ".cc" => :ClCompile,
    ".png" => :Image,
    ".asm" => :MASM,
    ".rc" => :ResourceCompile,
    ".natvis" => :Natvis,
  })
end

# Global attributes. Available in all nodes but not at top level.

JDL.attr "*/id", type: :string do
  title "TODO"
  flags :node_option
end

JDL.attr "*/root", type: :dir do
  title "TODO"
  flags :node_option
end

JDL.method "*/option_value" do
  title "Get value of previous set option"
  example %Q{
    src 'file.cpp', properties: {:MyProp => :MyVal}, vpath: 'MyDir'
    option_value(:src, :properties) # returns {:MyProp => :MyVal}
    option_value(:src, :vpath) # returns 'MyDir'
  }
end
