# frozen_string_literal: true

require_relative '../lib/jaba'
require 'optparse'
require 'ostruct'

opts = OpenStruct.new(
  dry_run: nil
)

OptionParser.new do |op|
  op.banner = 'Welcome to JABA'
  op.separator ''
  op.separator 'Options:'
  op.on('--dry-run', 'Dry run') { opts.dry_run = true }
  op.separator ''
end.parse

begin
  output = JABA.run do |j|
    j.dry_run = opts.dry_run if opts.dry_run
  end
rescue JABA::JDLError => e
  $stderr.puts e.message

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

