require_relative '../lib/jaba'

begin
  output = JABA.run
rescue JABA::JDLError => e
  $stderr.puts e.message

  # TODO: nasty
  # If there is a backtrace skip the first item as file and line info is included in main message
  #
  if e.backtrace.size > 1
    $stderr.puts 'Backtrace:'
    bt = e.backtrace
    bt.shift
    $stderr.puts(bt.map {|line| "  #{line}"})
  end
  exit 1
rescue => e
  $stderr.puts "Internal error: #{e.message}"
  $stderr.puts 'Backtrace:'
  $stderr.puts(e.backtrace.map {|line| "  #{line}"})
  exit 1
end

puts output[:summary]

output[:added].each do |f|
  puts "  #{f} [A]"
end

output[:modified].each do |f|
  puts "  #{f} [M]"
end

if output[:warnings]
  puts output[:warnings]
end

