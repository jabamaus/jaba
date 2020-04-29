# frozen_string_literal: true

# This file deals with invoking Jaba, whether running standalone or embedding in other code
#
require_relative 'core/services'
require_relative 'api/api_common'
require_relative 'api/top_level_api'
require_relative 'api/jaba_attribute_type_api'
require_relative 'api/jaba_attribute_flag_api'
require_relative 'api/jaba_attribute_definition_api'
require_relative 'api/jaba_type_api'
require_relative 'api/jaba_node_api'

##
#
module JABA

  using JABACoreExt

  ##
  # Jaba entry point. Returns a json-like hash object containing a summary of what has been generated.
  #
  def self.run
    s = Services.new
    yield s.input if block_given?
    s.run
  end

  ##
  # Input to pass to Jaba.
  #
  class Input
    
    ##
    # One or more filenames and/or directories from which to load definitions.
    #
    attr_accessor :load_paths
    
    ##
    #
    attr_block :definitions
    
    ##
    # Name/path of file to contain a raw dump of all the input data to Jaba, that is to say all the definition data. Mostly
    # useful for debugging and testing but could be useful as a second way of tracking definition changes in source control.
    # The file is written before any file generation occurs, and can be considered a specification of the final data.
    # Defaults to 'jaba.input.json', which will be created in cwd. By default this is disabled.
    #
    attr_accessor :jaba_input_file

    ##
    # Controls generation of :jaba_input_file. Off by default.
    #
    attr_bool :dump_input

    ##
    # Name/path of file to contain Jaba output in json format. Defaults to 'jaba.output.json', which will be created in cwd.
    # Jaba output can be later used by another process (eg the build process) to do things like looking up paths by id rather
    # than embedding them in code, iterating over all defined unit tests and invoking them, etc.
    #
    attr_accessor :jaba_output_file

    ##
    # Controls generation of :jaba_output_file. On by default.
    #
    attr_bool :dump_output

    ##
    # Enable logging. 'jaba.log' will be written to cwd. Off by default.
    #
    attr_bool :enable_logging

    ##
    # Causes definition file contents to be cached. Useful if Jaba will be executed more than once
    # in one process, and definition source files are NOT changing between runs (eg when during unit testing).
    # No benefit for single run invocations. Off by default.
    #
    attr_bool :use_file_cache

    ##
    # Uses a cache when globbing definition files. Same conditions as use_file_cache apply. Off by default.
    #
    attr_bool :use_glob_cache

    ##
    # Execute as normal but don't write any files.
    #
    attr_bool :dry_run
    
  end

  ##
  # Raised when there is an error raised from inside Jaba, either from the user definitions or from internal library
  # code.
  #
  class JabaError < StandardError
    
    ##
    #
    attr_reader :raw_message
    
    ##
    # The definition file the error occurred in.
    #
    attr_reader :file
    
    ##
    # The line in the definition file that the error occurred at.
    #
    attr_reader :line
    
  end

end

if $PROGRAM_NAME == __FILE__
  require 'optparse'
  require 'ostruct'

  options = OpenStruct.new(
    load_paths: nil,
    dump_input: nil,
    enable_logging: nil,
    dry_run: nil,
    enable_profiling: nil
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
    opts.separator ''
  end
  
  opts.parse!

  begin
    using JABACoreExt
    profile(enabled: options[:enable_profiling]) do
      op = JABA.run do |j|
        j.load_paths = options[:load_paths] if options[:load_paths]
        j.dump_input = options[:dump_input] if options[:dump_input]
        j.dry_run = options[:dry_run] if options[:dry_run]
        j.enable_logging = options[:enable_logging] if options[:enable_logging]
      end
      written = op[:generated]
      print "Wrote #{written.size} files:"
      print " [dry run]" if options[:dry_run]
      puts
      written.each do |w|
        puts "  #{w}"
      end
      warnings = op[:warnings]
      puts warnings if warnings
    end
  rescue StandardError => e
    puts e.message
    puts 'Backtrace:'
    puts(e.backtrace.map {|line| "  #{line}"})
  end
end
