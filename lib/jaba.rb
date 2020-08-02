if __FILE__ == $PROGRAM_NAME
  $stderr.puts "Library file cannot be executed"
  exit 1
end

require_relative 'jaba/core/services'
require_relative 'jaba/jdl_api/jdl_common'
require_relative 'jaba/jdl_api/jdl_attribute_definition'
require_relative 'jaba/jdl_api/jdl_node'
require_relative 'jaba/jdl_api/jdl_top_level'
require_relative 'jaba/jdl_api/jdl_translator'
require_relative 'jaba/jdl_api/jdl_type'

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
    #
    attr_accessor :src_root
    
    ##
    #
    attr_block :definitions
    
    ##
    # Pass command line in manually. Used in testing.
    #
    attr_accessor :argv

    ##
    # Execute as normal but don't write any files.
    #
    attr_bool :dry_run
    
    ##
    # Used during testing. Only loads the bare minimum definitions. Jaba will not be able to generate any projects in this mode. 
    #
    attr_bool :barebones
    
  end

  ##
  # Jaba Definition Language error.
  # Raised when there is an error in a definition. These errors should be fixable by the user by modifying the definition
  # file.
  #
  class JDLError < StandardError
    
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

  ##
  #
  class CommandLineUsageError < StandardError ; end

end
