# frozen_string_literal: true

# This file deals with invoking Jaba, whether running standalone or embedding in other code
#
require_relative 'core/services'
require_relative 'api/api_common'
require_relative 'api/top_level_api'
require_relative 'api/jaba_attribute_type_api'
require_relative 'api/jaba_attribute_definition_api'
require_relative 'api/jaba_type_api'
require_relative 'api/jaba_node_api'
require_relative 'api/api_common'

##
#
module JABA

  using JABACoreExt

  ##
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
    # Logging is disabled by default for performance.
    #
    attr_bool :enable_logging

    ##
    # Causes definition file contents to be cached. Useful if Jaba will be executed more than once
    # in one process, eg when during unit testing. Off by default.
    #
    attr_bool :use_file_cache
    
  end

  ##
  # Output from Jaba, returned by JABA.run.
  #
  class Output

    ##
    # Array of files generated by this run of JABA.
    #
    attr_reader :generated_files
    
    ##
    # Array of any warnings that were generated.
    #
    attr_reader :warnings
    
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
    # True if error is an internal error as opposed to a user error in the definitions.
    #
    attr_reader :internal
    
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
  begin
    JABA.run do |j|
      j.load_paths = Dir.getwd
      j.enable_logging = ARGV.delete('--log') ? true : false
    end
  rescue JABA::JabaError => e
    puts e.message
    puts 'Backtrace:'
    puts(e.backtrace.map {|line| "  #{line}"})
  end
end
