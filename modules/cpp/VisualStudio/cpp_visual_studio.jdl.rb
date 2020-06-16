open_type :globals do
  attr_hash :vcfiletype, type: :symbol do
    flags :required
  end
end

open_instance :globals, type: :globals do
  vcfiletype '.h', :ClInclude
  vcfiletype '.inl', :ClInclude
  vcfiletype '.hpp', :ClInclude
  vcfiletype '.cpp', :ClCompile
  vcfiletype '.c', :ClCompile
  vcfiletype '.cxx', :ClCompile
  vcfiletype '.cc', :ClCompile
  vcfiletype '.png', :Image
  vcfiletype '.asm', :MASM
  vcfiletype '.rc', :ResourceCompile
  vcfiletype '.natvis', :Natvis
end

open_shared :vscommon do
  cpp_project_classname 'Vcxproj'
end

open_type :arch do
  attr :vsname do
    flags :expose
    help 'Name of target architecture (platform) as seen in Visual Studio IDE'
  end
end

open_instance :x86, type: :arch do
  vsname 'Win32'
end

open_instance :x86_64, type: :arch do
  vsname 'x64'
end

open_instance :arm64, type: :arch do
  vsname 'ARM64'
end
