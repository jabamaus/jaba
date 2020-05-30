cpp :MyLib do
  type :lib
  hosts [:vs2019]
  platforms [:windows]
  archs [:x86, :x86_64]
  configs [:Debug, :Release]
  src ['**/*']
end
