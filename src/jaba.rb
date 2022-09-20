if __FILE__ == $PROGRAM_NAME
  $stderr.puts "Library file cannot be executed"
  exit 1
end

$LOAD_PATH.unshift "#{__dir__}/../../jrf"
require_relative 'version'
require_relative 'core/services'

module JABA

  ##
  # Jaba entry point. Returns a json-like hash object containing a summary of what has been generated.
  #
  def self.run(want_exceptions: false, test_mode: false)
    s = Services.new(test_mode: test_mode)
    begin
      s.execute do
        yield s.input if block_given?
        s.run
      end
    rescue
      if want_exceptions
        raise
      else
        return s.output
      end
    end
  end

  ##
  # Input to pass to Jaba.
  #
  class Input
    
    ##
    # Input root. Defaults to current working directory.
    #
    attr_accessor :src_root

    ##
    # Output/dest root. Defaults to current working directory.
    #
    attr_accessor :build_root
    
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

    ##
    #
    attr_bool :dump_output
    
    ##
    #
    attr_bool :dump_state

    ##
    # Initialise global attrs from a hash of name to value(s)
    #
    attr_accessor :global_attrs
    
  end

  ##
  # Jaba Definition Language error.
  # Raised when there is an error in a definition. These errors should be fixable by the user by modifying the definition
  # file.
  #
  class JabaError < StandardError
    
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
