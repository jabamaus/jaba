require_relative '../src/jaba'

output = JABA.run

if output[:error]
  $stderr.puts output[:error]
  exit 1
end

puts output[:summary]
puts output[:warnings]

