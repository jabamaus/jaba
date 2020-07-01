cpp :MyApp do
  type :console
  hosts [:vs2019]
  platforms [:windows]
  archs [:x86, :x86_64]
  configs [:Debug, :Release]
  src ['.']
end

workspace :MyWorkspace do
  projects [:MyApp]
end