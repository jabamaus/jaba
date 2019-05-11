# This file deals with invoking Jaba, whether running standalone or embedding in other code
#
require_relative 'core/Services'
require_relative 'DefinitionAPI'

module JABA

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
  #
  attr_accessor :root
  
  ##
  # One or more filenames and/or directories from which to load definitions.
  #
  attr_accessor :load_paths
  
  ##
  #
  attr_block :definitions
  
end

##
# Output from Jaba, returned by JABA.run.
#
class Output

  ##
  # Array of files newly created by this run of JABA.
  #
  attr_reader :added_files
  
  ##
  # Array of existing files that were modified by this run of JABA.
  #
  attr_reader :modified_files
  
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
  # True if error is an internal error as opposed to a user error in the definitions.
  #
  attr_boolean :internal
  
  ##
  # The definition file the error occurred in. Not available if definitions were executed as a block.
  #
  attr_reader :file
  
  ##
  # The line in the definition file that the error occurred at. Not available if definitions were executed as a block.
  #
  attr_reader :line
  
end

end

if __FILE__ == $0
  JABA.run
end
