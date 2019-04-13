module JABA

require_relative 'core/Services'

##
#
def self.run(&block)
  s = Services.new(&block)
  yield s.input
  s.run
end

##
# Input to pass to Jaba.
#
class Input
  
  attr_block :definitions
  
  ##
  # Print verbose output? Defaults to false.
  #
  attr_boolean :verbose
  
end

##
# Output from Jaba, returned by Jaba.run.
#
class Output
end

##
#
module CommonDefinitionAPI
end

##
# The API available for defining projects, workspaces, targets etc.
#
class TopLevelDefinitionsAPI < BasicObject
  
  include CommonDefinitionAPI
  
  ##
  # Define a target.
  #
  def target(name, &block)
  end
  
  ##
  # Define a project.
  #
  def project(name, &block)
  end
  
  ##
  # Define a workspace.
  #
  def workspace(name, &block)
  end
  
  ##
  # Define a category.
  #
  def category(name, &block)
  end
  
  ##
  # Define definition to be included by other definitions.
  #
  def shared(&block)
  end
  
end

##
# Raised when there is an error in the user definitions.
#
class DefinitionError < StandardError
  
  # The definition that the error occurred in. nil if the error did not happen inside a definition.
  #
  attr_reader :definition_id
  
  # The type of the definition that the error occurred in (eg text_file/cpp). nil if the error did not happen inside
  # a definition.
  #
  attr_reader :definition_type
  
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
