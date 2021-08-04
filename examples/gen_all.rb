def iterate_examples
  Dir.chdir(__dir__) do
    Dir.glob('*').select{|d| File.directory?(d) && d =~ /^[\d]+-/}.each do |dir|
      yield dir, "#{__dir__}/#{dir}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  iterate_examples do |dir|
    Dir.chdir(dir) do
      puts "Running jaba in #{dir}..."
      if !system('jaba.bat')
        puts "Jaba FAILED"
        exit!
      end
    end
  end

  puts "Done!"
end