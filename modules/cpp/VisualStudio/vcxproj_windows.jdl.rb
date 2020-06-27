translator :vcxproj_windows do |vcxproj|
  vcglobal :ProjectName, projname
  vcglobal :ProjectGuid, guid
  vcglobal :Keyword, 'Win32Proj'
  vcglobal :RootNamespace, projname
  vcglobal :WindowsTargetPlatformVersion, winsdkver
end

translator :vcxproj_config_windows do |vcxproj, cfg_type|
  
  # First set of property groups
  #
  vcproperty :ConfigurationType, group: :pg1 do
    case cfg_type
    when :app, :console
      'Application'
    when :lib
      'StaticLibrary'
    when :dll
      'DynamicLibrary'
    else
      fail "'#{cfg_type}' unhandled"
    end
  end

  vcproperty :UseDebugLibraries, debug, group: :pg1

  vcproperty :CharacterSet, group: :pg1 do
    case character_set
    when :mbcs
      :MultiByte
    when :unicode
      :Unicode
    end
  end

  vcproperty :PlatformToolset, toolset, group: :pg1

  # Second set of property groups
  #
  vcproperty :OutDir, group: :pg2 do
    if cfg_type == :lib
      libdir.relative_path_from(vcxproj.projroot, backslashes: true, trailing: true)
    else
      bindir.relative_path_from(vcxproj.projroot, backslashes: true, trailing: true)
    end
  end

  vcproperty :IntDir, group: :pg2 do
    objdir.relative_path_from(vcxproj.projroot, backslashes: true, trailing: true)
  end

  vcproperty :TargetName, targetname, group: :pg2
  vcproperty :TargetExt, targetext, group: :pg2

  # ClCompile
  #
  vcproperty :AdditionalIncludeDirectories, group: :ClCompile do
    inc.map{|i| i.relative_path_from(vcxproj.projroot, backslashes: true)}.vs_join_paths(inherit: '%(AdditionalIncludeDirectories)')
  end

  vcproperty :AdditionalOptions, group: :ClCompile do
    cflags.vs_join(separator: ' ', inherit: '%(AdditionalOptions)')
  end

  vcproperty :DisableSpecificWarnings, group: :ClCompile do
    nowarn.vs_join(inherit: '%(DisableSpecificWarnings)')
  end

  vcproperty :ExceptionHandling, group: :ClCompile do
    case exceptions
    when true
      :Sync
    when false
      false
    when :structured
      :Async
    else
      fail "'#{exceptions}' unhandled"
    end
  end

  vcproperty :PreprocessorDefinitions, group: :ClCompile do
    defines.vs_join(inherit: '%(PreprocessorDefinitions)')
  end

  vcproperty :RuntimeTypeInfo, rtti, group: :ClCompile

  vcproperty :TreatWarningAsError, warnerror, group: :ClCompile

  # Link
  #
  if cfg_type != :lib
    vcproperty :SubSystem, group: :Link do
      case cfg_type
      when :console
        :Console
      when :app, :dll
        :Windows
      else
        fail "'#{type}' unhandled"
      end
    end
  end

  vcproperty :TargetMachine, group: (cfg_type == :lib ? :Lib : :Link) do
    :MachineX64 if x86_64?
  end

end
