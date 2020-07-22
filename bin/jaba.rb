# frozen_string_literal: true

require_relative '../lib/jaba'
require 'optparse'
require 'ostruct'

opts = OpenStruct.new(
  jdl_paths: nil,
  enable_logging: nil,
  dry_run: nil
)

OptionParser.new do |op|
  op.banner = 'Welcome to JABA'
  op.separator ''
  op.separator 'Options:'
  op.on('--jdl-path P', "JDL paths") {|lp| opts.jdl_paths = p }
  op.on('--log', 'Enable logging') { opts.enable_logging = true}
  op.on('--dry-run', 'Dry run') { opts.dry_run = true }
  op.separator ''
end.parse

begin
  output = JABA.run do |j|
    j.jdl_paths = opts.jdl_paths if opts.jdl_paths
    j.dry_run = opts.dry_run if opts.dry_run
    j.enable_logging = opts.enable_logging if opts.enable_logging
  end
rescue JABA::JDLError => e
  puts e.message

  # If there is a backtrace skip the first item as file and line info is included in main message
  #
  if e.backtrace.size > 1
    puts 'Backtrace:'
    bt = e.backtrace
    bt.shift
    puts(bt.map {|line| "  #{line}"})
  end
  exit 1
rescue => e
  puts "Internal error: #{e.message}"
  puts 'Backtrace:'
  puts(e.backtrace.map {|line| "  #{line}"})
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

