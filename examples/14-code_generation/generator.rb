require 'FileUtils'
require_relative '../../lib/jaba/core/core_ext'

using JABACoreExt

src_file = ARGV[0].cleanpath
cpp_file = ARGV[1].cleanpath
header_file = cpp_file.sub('.cpp', '.h') 

cpp = "#include <stdio.h>\n\n"
header = "#pragma once\n"

IO.readlines(src_file, chomp: true).each do |method_name|
  cpp << "void #{method_name}()\n"
  cpp << "{\n"
  cpp << "  printf(\"#{method_name}\\n\");\n"
  cpp << "}\n\n"
  header << "void #{method_name}();\n"
end

FileUtils.mkdir(cpp_file.parent_path) if !File.exist?(cpp_file.parent_path)
IO.write(cpp_file, cpp)
IO.write(header_file, header)
