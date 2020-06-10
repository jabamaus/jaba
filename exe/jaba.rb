# frozen_string_literal: true

require_relative '../lib/jaba/jaba'
require 'optparse'
require 'ostruct'

using JABACoreExt

opts = OpenStruct.new(
  jdl_paths: nil,
  dump_input: nil,
  no_dump_output: nil,
  enable_logging: nil,
  dry_run: nil,
  enable_profiling: nil,
  run_tests: nil
)

OptionParser.new do |op|
  op.banner = 'Welcome to JABA'
  op.separator ''
  op.separator 'Options:'
  op.on('--jdl-path P', "JDL paths") {|lp| opts.jdl_paths = p }
  op.on('--dump-input', 'Dumps Jaba input') { opts.dump_input = true }
  op.on('--no-dump-output', 'Disables dumping of jaba output') { opts.no_dump_output = true }
  op.on('--log', 'Enable logging') { opts.enable_logging = true}
  op.on('--dry-run', 'Dry run') { opts.dry_run = true }
  op.on('--profile', 'Profile jaba with ruby-prof gem') { opts.enable_profiling = true }
  op.on('--test', 'Run tests') { opts.run_tests = true }
  op.separator ''
end.parse!

##
#
def profile(enabled)
  if !enabled
    yield
    return
  end

  begin
    require 'ruby-prof'
  rescue LoadError
    puts "'gem install ruby-prof' is required to run with --profile"
    exit 1
  end

  puts 'Invoking ruby-prof...'
  RubyProf.start
  yield
  result = RubyProf.stop
  file = 'jaba.profile'.to_absolute
  str = String.new
  puts "Write profiling results to #{file}..."
  [RubyProf::FlatPrinter, RubyProf::GraphPrinter].each do |p|
    printer = p.new(result)
    printer.print(str)
  end
  IO.write(file, str)
end

if opts.run_tests
  require_relative "../test/test_jaba"
  JABA.init_tests
  profile(opts.enable_profiling) do
    JABA.run_tests
  end
  exit
end
  
begin
  output = nil
  profile(opts.enable_profiling) do
    output = JABA.run do |j|
      j.jdl_paths = opts.jdl_paths if opts.jdl_paths
      j.dump_input = opts.dump_input if opts.dump_input
      j.dump_output = false if opts.no_dump_output
      j.dry_run = opts.dry_run if opts.dry_run
      j.enable_logging = opts.enable_logging if opts.enable_logging
    end
  end

  added = output[:added]
  modified = output[:modified]
  warnings = output[:warnings]

  puts output[:summary]
  
  added.each do |f|
    puts "  #{f} [A]"
  end
  modified.each do |f|
    puts "  #{f} [M]"
  end
  puts warnings if warnings
rescue JABA::JDLError => e
  puts e.message
  if !e.backtrace.empty?
    puts 'Backtrace:'
    puts(e.backtrace.map {|line| "  #{line}"})
  end
  exit 1
rescue => e
  puts "Internal error: #{e.message}"
  puts 'Backtrace:'
  puts(e.backtrace.map {|line| "  #{line}"})
  exit 1
end
