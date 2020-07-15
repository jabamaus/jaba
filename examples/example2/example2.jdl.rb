cpp :MyLib do
  type :lib
  hosts [:vs2019], platforms: [:windows_x86, :windows_x86_64]
  configs [:Debug, :Release]
  src ['.']
end
