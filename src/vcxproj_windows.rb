JABA::Vcxproj.project_builder(:windows) do |vcxproj|
  vcglobal :ProjectGuid, "{#{vcxproj.guid}}"
  vcglobal :Keyword, "Win32Proj"
  vcglobal :RootNamespace, projname
  vcglobal :WindowsTargetPlatformVersion, winsdkver
  vcglobal :IgnoreWarnCompileDuplicatedFilename, true
end

JABA::Vcxproj.config_builder(:windows) do |vcxproj, cfg_type|
  # PG1
  #
  vcprop "PG1|ConfigurationType" do
    case cfg_type
    when :app, :console
      "Application"
    when :lib
      "StaticLibrary"
    when :dll
      "DynamicLibrary"
    else
      fail "'#{cfg_type}' unhandled"
    end
  end

  vcprop "PG1|UseDebugLibraries", debug

  vcprop "PG1|CharacterSet" do
    case charset
    when :mbcs
      :MultiByte
    when :unicode
      :Unicode
    end
  end

  vcprop "PG1|PlatformToolset", vctoolset

  # PG2
  #
  if cfg_type != :lib
    vcprop "PG2|LinkIncremental" do
      false
    end
  end

  vcprop "PG2|OutDir" do
    if cfg_type == :lib
      libdir.relative_path_from(vcxproj.projdir, backslashes: true, trailing: true)
    else
      bindir.relative_path_from(vcxproj.projdir, backslashes: true, trailing: true)
    end
  end

  vcprop "PG2|IntDir" do
    objdir.relative_path_from(vcxproj.projdir, backslashes: true, trailing: true)
  end

  vcprop "PG2|TargetName", targetname
  vcprop "PG2|TargetExt", targetext

  # ClCompile
  #
  vcprop "ClCompile|AdditionalIncludeDirectories" do
    inc.map do |i|
      i.relative_path_from(vcxproj.projdir, backslashes: true)
    end.vs_join_paths(inherit: "%(AdditionalIncludeDirectories)")
  end

  vcprop "ClCompile|AdditionalOptions" do
    cflags.vs_join(separator: " ", inherit: "%(AdditionalOptions)")
  end

  vcprop "ClCompile|DebugInformationFormat" do
    "ProgramDatabase"
  end

  vcprop "ClCompile|DisableSpecificWarnings" do
    vcnowarn.vs_join(inherit: "%(DisableSpecificWarnings)")
  end

  vcprop "ClCompile|ExceptionHandling" do
    case exceptions
    when true
      nil # Visual Studio enables exception handling by default so don't add to vcxproj
    when false
      false
    when :structured
      :Async
    else
      fail "'#{exceptions}' unhandled"
    end
  end

  vcprop "ClCompile|InlineFunctionExpansion", :AnySuitable if !debug?

  vcprop "ClCompile|LanguageStandard" do
    case cpplang
    when "C++11"
      :stdcpp11
    when "C++14"
      :stdcpp14
    when "C++17"
      :stdcpp17
    when "C++20"
      :stdcpp20
    when "C++23"
      :stdcpplatest
    else
      fail "#{cpplang} not supported by Visual Studio"
    end
  end

  vcprop 'ClCompile|MultiProcessorCompilation', true
  
  vcprop 'ClCompile|PrecompiledHeader' do
    :Use if !pch.empty?
  end

  vcprop 'ClCompile|PrecompiledHeaderFile' do
    pch if !pch.empty?
  end

  vcprop "ClCompile|PreprocessorDefinitions" do
    define.vs_join(inherit: "%(PreprocessorDefinitions)")
  end

  vcprop "ClCompile|RuntimeTypeInfo", true if rtti

  vcprop "ClCompile|TreatWarningAsError", true if warnerror

  vcprop "ClCompile|WarningLevel", "Level#{vcwarnlevel}"

  # Link
  #
  vcprop "#{cfg_type == :lib ? :Lib : :Link}|AdditionalDependencies" do
    all_libs = libs.map { |l| l.relative_path_from(vcxproj.projdir, backslashes: true) } + syslibs
    all_libs.vs_join_paths(inherit: "%(AdditionalDependencies)")
  end

  vcprop "#{cfg_type == :lib ? :Lib : :Link}|AdditionalOptions" do
    lflags.vs_join(separator: " ", inherit: "%(AdditionalOptions)")
  end

  if cfg_type != :lib
    vcprop "Link|SubSystem" do
      case cfg_type
      when :console
        :Console
      when :app, :dll
        :Windows
      else
        fail "'#{type}' unhandled"
      end
    end
    vcprop "ProjectReference|LinkLibraryDependencies", false
  end

  if cfg_type == :dll
    il = vcimportlib
    if il
      vcprop "Link|ImportLibrary" do
        il.relative_path_from(vcxproj.projdir, backslashes: true)
      end
    end
  end

  vcprop "#{cfg_type == :lib ? :Lib : :Link}|TargetMachine" do
    :MachineX64 if x86_64?
  end

  # Resources
  #
  #if vcxproj.has_resources
  #  vcprop "ResourceCompile|AdditionalIncludeDirectories" do
  #    res_inc.map do |i|
  #      i.relative_path_from(vcxproj.projdir, backslashes: true)
  #    end.vs_join_paths
  #  end
  #end
end
