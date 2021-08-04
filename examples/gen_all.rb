Dir.chdir(__dir__) do
  Dir.glob('*').select{|d| File.directory?(d) && d =~ /^[\d]+-/}.each do |example|
    Dir.chdir(example) do
      puts "Running jaba in #{example}..."
      if !system('jaba.bat')
        puts "Jaba FAILED"
        exit!
      end
    end
  end
end
puts "Done!"