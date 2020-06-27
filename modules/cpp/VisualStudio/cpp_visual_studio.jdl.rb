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

open_shared :vs_host_common do
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

open_type :cpp do
  open_type :per_platform do
    attr :guid, type: :uuid do
      title 'Globally unique id (GUID)'
      help 'Seeded by <projname>. Required by Visual Studio project files'
      default { projname }
    end

    attr_hash :vcglobal do
      help 'Directly address the Globals property group in a vcxproj'
      value_option :condition
      flag_options :export
    end

    attr :winsdkver, type: :choice do
      help 'Windows SDK version. Defaults to nil.'
      items [
        '10.0.16299.0',  # Included in VS2017 ver.15.4
        '10.0.17134.0',  # Included in VS2017 ver.15.7
        '10.0.17763.0',  # Included in VS2017 ver.15.8
        '10.0.18362.0',  # Included in VS2019
        nil
      ]
      default nil
    end
  end

  open_type :config do
    attr_hash :vcproperty do
      help 'Address config section of a vcxproj directly'
      value_option :group, required: true
      value_option :condition
      flag_options :export
    end
  end
end

open_type :category do
  attr :guid, type: :uuid do
    title 'Globally unique id (GUID)'
    help 'Seeded by <name>. Required by Visual Studio .sln files'
    default { name }
  end
end
