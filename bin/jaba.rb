require_relative '../lib/jaba'

output = JABA.run
err = output[:error]

if err
  $stderr.puts err[:msg]
  exit 1
end

puts output[:summary]

output[:added].each {|f| puts "  #{f} [A]"}
output[:modified].each {|f| puts "  #{f} [M]"}

puts output[:warnings]

