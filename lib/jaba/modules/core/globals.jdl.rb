define :globals do

  attr_hash :vcfiletype, type: :symbol do
    flags :required
  end
  
end

globals :globals do
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
  
