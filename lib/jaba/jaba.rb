# frozen_string_literal: true

require_relative 'api/jaba_context'

if $PROGRAM_NAME == __FILE__
  require 'optparse'
  require 'ostruct'

  options = OpenStruct.new(
    load_paths: nil,
    dump_input: nil,
    enable_logging: nil,
    dry_run: nil,
    enable_profiling: nil,
    run_tests: nil
  )

  opts = OptionParser.new do |opts|
    opts.banner = <<EOB
  Welcome to JABA
EOB
    opts.separator ''
    opts.separator 'Options:'
  
    opts.on('-l', '--load-path LP', "Load path") do |lp|
      options[:load_paths] = lp
    end
    opts.on('--dump-input', 'Dumps Jaba input') do |d|
      options[:dump_input] = d
    end
    opts.on('--log', 'Enable logging') do |log|
      options[:enable_logging] = log
    end
    opts.on('--dry-run', 'Dry run') do |d|
      options[:dry_run] = d
    end
    opts.on('--profile', 'Profile jaba run with ruby-prof') do |p|
      options[:enable_profiling] = p
    end
    opts.on('--test', 'Run tests') do |d|
      options[:run_tests] = d
    end
    opts.separator ''
  end
  
  opts.parse!

  module DidYouMean::Correctable
    remove_method :to_s
  end

  begin
    if options[:run_tests]
      require_relative "../../test/test_jaba"
    end
    using JABACoreExt
    op = nil
    profile(enabled: options[:enable_profiling]) do
      op = JABA.run do |j|
        j.load_paths = options[:load_paths] if options[:load_paths]
        j.dump_input = options[:dump_input] if options[:dump_input]
        j.dry_run = options[:dry_run] if options[:dry_run]
        j.enable_logging = options[:enable_logging] if options[:enable_logging]
      end
    end
    generated = op[:generated]
    added = op[:added_files]
    modified = op[:modified_files]
    print "Generated #{generated.size} files, #{added.size} added, #{modified.size} modified"
    print " [dry run]" if options[:dry_run]
    puts
    cwd = Dir.getwd
    added.each do |f|
      puts "  #{f.relative_path_from(cwd)} [A]"
    end
    modified.each do |f|
      puts "  #{f.relative_path_from(cwd)} [M]"
    end
    warnings = op[:warnings]
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
end
