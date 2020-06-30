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
  vcproperty 'PG1|ConfigurationType' do
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

  vcproperty 'PG1|UseDebugLibraries', debug

  vcproperty "PG1|CharacterSet" do
    case character_set
    when :mbcs
      :MultiByte
    when :unicode
      :Unicode
    end
  end

  vcproperty 'PG1|PlatformToolset', toolset

  # Second set of property groups
  #
  vcproperty 'PG2|OutDir' do
    if cfg_type == :lib
      libdir.relative_path_from(vcxproj.projdir, backslashes: true, trailing: true)
    else
      bindir.relative_path_from(vcxproj.projdir, backslashes: true, trailing: true)
    end
  end

  vcproperty 'PG2|IntDir' do
    objdir.relative_path_from(vcxproj.projdir, backslashes: true, trailing: true)
  end

  vcproperty 'PG2|TargetName', targetname
  vcproperty 'PG2|TargetExt', targetext

  # ClCompile
  #
  vcproperty 'ClCompile|AdditionalIncludeDirectories' do
    inc.map{|i| i.relative_path_from(vcxproj.projdir, backslashes: true)}.vs_join_paths(inherit: '%(AdditionalIncludeDirectories)')
  end

  vcproperty 'ClCompile|AdditionalOptions' do
    cflags.vs_join(separator: ' ', inherit: '%(AdditionalOptions)')
  end

  vcproperty 'ClCompile|DisableSpecificWarnings' do
    nowarn.vs_join(inherit: '%(DisableSpecificWarnings)')
  end

  vcproperty 'ClCompile|ExceptionHandling' do
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

  vcproperty 'ClCompile|PreprocessorDefinitions' do
    defines.vs_join(inherit: '%(PreprocessorDefinitions)')
  end

  vcproperty 'ClCompile|RuntimeTypeInfo', rtti

  vcproperty 'ClCompile|TreatWarningAsError', warnerror

  # Link
  #
  if cfg_type != :lib
    vcproperty 'Link|SubSystem' do
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

  vcproperty "#{cfg_type == :lib ? :Lib : :Link}|TargetMachine" do
    :MachineX64 if x86_64?
  end

end
