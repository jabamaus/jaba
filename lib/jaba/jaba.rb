# frozen_string_literal: true

require_relative 'api/jaba_context'
require 'optparse'
require 'ostruct'

opts = OpenStruct.new(
  load_paths: nil,
  dump_input: nil,
  enable_logging: nil,
  dry_run: nil,
  enable_profiling: nil,
  run_tests: nil
)

OptionParser.new do |op|
  op.banner = 'Welcome to JABA'
  op.separator ''
  op.separator 'Options:'
  op.on('-l', '--load-path LP', "Load path") {|lp| opts.load_paths = lp }
  op.on('--dump-input', 'Dumps Jaba input') { opts.dump_input = true }
  op.on('--log', 'Enable logging') { opts.enable_logging = true}
  op.on('--dry-run', 'Dry run') { opts.dry_run = true }
  op.on('--profile', 'Profile jaba run with ruby-prof') { opts.enable_profiling = true }
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
  
  puts 'Invoking ruby-prof...'
  require 'ruby-prof'
  RubyProf.start
  yield
  result = RubyProf.stop
  file = File.expand_path('jaba.profile')
  str = String.new
  puts "Write profiling results to #{file}..."
  [RubyProf::FlatPrinter, RubyProf::GraphPrinter].each do |p|
    printer = p.new(result)
    printer.print(str)
  end
  IO.write(file, str)
end

if opts.run_tests
  require_relative "../../test/test_jaba"
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
      j.load_paths = opts.load_paths if opts.load_paths
      j.dump_input = opts.dump_input if opts.dump_input
      j.dry_run = opts.dry_run if opts.dry_run
      j.enable_logging = opts.enable_logging if opts.enable_logging
    end
  end

  generated = output[:generated]
  added = output[:added_files]
  modified = output[:modified_files]
  warnings = output[:warnings]

  print "Generated #{generated.size} files, #{added.size} added, #{modified.size} modified"
  print " [dry run]" if opts.dry_run
  puts
  
  cwd = Dir.getwd
  added.each do |f|
    puts "  #{f.relative_path_from(cwd)} [A]"
  end
  modified.each do |f|
    puts "  #{f.relative_path_from(cwd)} [M]"
  end
  puts warnings if warnings
rescue JABA::JabaDefinitionError => e
  puts e.message
  if !e.backtrace.empty?
    puts 'Backtrace:'
    puts(e.backtrace.map {|line| "  #{line}"})
  end
rescue => e
  puts "Internal error: #{e.message}"
  puts 'Backtrace:'
  puts(e.backtrace.map {|line| "  #{line}"})
end
