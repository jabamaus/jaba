src_file = ARGV[0]
cpp_file = src_file.sub('.xyz', '.cpp')
method_name = IO.readlines(ARGV[0])[0]

cpp = "void #{method_name}()\n"
cpp << "{\n"
cpp << "  printf(\"#{method_name}\");\n"
cpp << "}\n\n"

puts "Generating #{cpp_file}"
Dir.chdir("#{__dir__}/generated") do
  IO.write(cpp_file, cpp)
end
