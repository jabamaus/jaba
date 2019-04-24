require_relative 'core/Services'
require_relative 'ExtensionAPI'

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
  #
  attr_block :definitions
  
  ##
  # Print verbose output? Defaults to false.
  #
  attr_boolean :verbose
  
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
#
module CommonDefinitionAPI
end

##
#
class Globals < BasicObject
  
  include CommonDefinitionAPI
  include GlobalExtensions
  
  ##
  # Define a target.
  #
  def target(id=nil, **options, &block)
    @services.register_definition(:target, id, **options, &block)
  end
  
  ##
  # Define a project.
  #
  def project(id=nil, **options, &block)
    @services.register_definition(:project, id, **options, &block)
  end
  
  ##
  # Define a workspace.
  #
  def workspace(id=nil, **options, &block)
    @services.register_definition(:workspace, id, **options, &block)
  end
  
  ##
  # Define a category.
  #
  def category(id=nil, **options, &block)
    @services.register_definition(:category, id, **options, &block)
  end
  
  ##
  # Define definition to be included by other definitions.
  #
  def shared(id=nil, **options, &block)
    @services.register_definition(:shared, id, **options, &block)
  end
  
  def __internal_set_services(s)
    @services = s
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

if __FILE__ == $0
  JABA.run
end
