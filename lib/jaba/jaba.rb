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
# Raised when there is an error in the user definitions.
#
class DefinitionError < StandardError
  
  # The type of the definition that the error occurred in (eg project/workspace). nil if the error did not happen inside
  # a definition.
  #
  attr_reader :definition_type

  # The definition that the error occurred in. nil if the error did not happen inside a definition.
  #
  attr_reader :definition_id
  
  ##
  # The definition file the error occurred in. Not available if definitions were executed as a block.
  #
  attr_reader :file
  
  ##
  # The line in the definition file that the error occurred at. Not available if definitions were executed as a block.
  #
  attr_reader :line
  
  ##
  # Convenience for combining definition_id, definition_type, file and line into a string, depending on context.
  #
  attr_reader :where
  
end

end

if __FILE__ == $0
  JABA.run
end
