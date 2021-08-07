require 'FileUtils'
require_relative '../../lib/jaba/core/core_ext'

using JABACoreExt

outdir = "#{__dir__}/generated"
src_file = ARGV[0].cleanpath
cpp_file = "#{outdir}/#{src_file.basename.sub('.xyz', '.cpp')}"
header_file = cpp_file.sub('.cpp', '.h') 

puts "Processing #{src_file} -> #{cpp_file}"

cpp = "#include <stdio.h>\n\n"
header = "#pragma once\n"

IO.readlines(src_file, chomp: true).each do |method_name|
  cpp << "void #{method_name}()\n"
  cpp << "{\n"
  cpp << "  printf(\"#{method_name}\\n\");\n"
  cpp << "}\n\n"

  header << "void #{method_name}();\n"
end

FileUtils.mkdir(outdir) if !File.exist?(outdir)
IO.write(cpp_file, cpp)
IO.write(header_file, header)
