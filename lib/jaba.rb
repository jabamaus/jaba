if $PROGRAM_NAME
  $stderr.puts "Library file cannot be executed"
  exit 1
end

require 'jaba/core/services'
require 'jaba/jdl_api/api_common'
require 'jaba/jdl_api/jaba_attribute_type_api'
require 'jaba/jdl_api/jaba_attribute_flag_api'
require 'jaba/jdl_api/jaba_attribute_definition_api'
require 'jaba/jdl_api/jaba_node_api'
require 'jaba/jdl_api/jaba_top_level_api'
require 'jaba/jdl_api/jaba_type_api'

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
    # One or more filenames and/or directories from which to load Jaba Definition Language definitions.
    #
    attr_accessor :jdl_paths
    
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

end
