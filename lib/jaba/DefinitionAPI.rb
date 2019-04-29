module JABA

##
#
class DefinitionAPI < BasicObject

  ##
  # Internal use only.
  #
  def __internal_set_obj(o)
    @obj = o
  end
  
end

require_relative 'ExtensionAPI'

##
# API for creating instances of Jaba types.
#
class TopLevelDefinitionAPI < DefinitionAPI
  
  include TopLevelDefinitionExtensionAPI
  
  ##
  #
  def src_tree(id=nil, **option, &block)
    @obj.register_definition(:src_tree, id, **options, &block)
  end
  
  ##
  # Define a target.
  #
  def target(id=nil, **options, &block)
    @obj.register_definition(:target, id, **options, &block)
  end
  
  ##
  # Define a project.
  #
  def project(id=nil, **options, &block)
    @obj.register_definition(:project, id, **options, &block)
  end
  
  ##
  # Define a workspace.
  #
  def workspace(id=nil, **options, &block)
    @obj.register_definition(:workspace, id, **options, &block)
  end
  
  ##
  # Define a category.
  #
  def category(id=nil, **options, &block)
    @obj.register_definition(:category, id, **options, &block)
  end
  
  ##
  # Define definition to be included by other definitions.
  #
  def shared(id=nil, **options, &block)
    @obj.register_definition(:shared, id, **options, &block)
  end
  
end

end
