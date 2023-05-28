def iterate_examples
  Dir.chdir(__dir__) do
    Dir.glob('*-*').each do |dir|
      yield dir, "#{__dir__}/#{dir}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  iterate_examples do |dir, full_dir|
    cmdline = "jaba -S #{dir}"
    puts cmdline
    if !system(cmdline)
      puts "Jaba FAILED"
    end
    puts
  end
  puts "Done!"
end