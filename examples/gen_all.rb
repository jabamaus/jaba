def iterate_examples
  Dir.chdir(__dir__) do
    Dir.glob('*-*').each do |dir|
      yield dir, "#{__dir__}/#{dir}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  iterate_examples do |dir|
    Dir.chdir(dir) do
      puts "Running jaba in #{dir}..."
      cmdline = 'jaba -D target_host vs2022'
      case dir
      when /parameterisable/
        cmdline << " -D cpp_default_lib_type lib"# -D buildsystem_root buildsystem_dynamic"
      end
      if !system(cmdline)
        puts "Jaba FAILED"
      end
    end
  end

  puts "Done!"
end