module JABA

##
#
class APIBase < BasicObject

  ##
  # Internal use only.
  #
  def __internal_set_obj(o)
    @obj = o
  end
  
  ##
  #
  def raise(msg)
    @obj.instance_variable_get(:@services).definition_error(msg) # TODO: improve
  end
  
end

require_relative 'ExtensionAPI'

##
# API for creating instances of Jaba types.
#
class TopLevelAPI < APIBase
  
  include TopLevelExtensionAPI
  
  ##
  #
  def src_tree(id=nil, **option, &block)
    @obj.define_instance(:src_tree, id, **options, &block)
  end
  
  ##
  # Define a target.
  #
  def target(id=nil, **options, &block)
    @obj.define_instance(:target, id, **options, &block)
  end
  
  ##
  # Define a project.
  #
  def project(id=nil, **options, &block)
    @obj.define_instance(:project, id, **options, &block)
  end
  
  ##
  # Define a workspace.
  #
  def workspace(id=nil, **options, &block)
    @obj.define_instance(:workspace, id, **options, &block)
  end
  
  ##
  # Define a category.
  #
  def category(id=nil, **options, &block)
    @obj.define_instance(:category, id, **options, &block)
  end
  
  ##
  # Define definition to be included by other definitions.
  #
  def shared(id=nil, **options, &block)
    @obj.define_instance(:shared, id, **options, &block)
  end
  
  ##
  #
  def text(id=nil, **options, &block)
    @obj.define_instance(:text, id, **options, &block)
  end
  
end

##
#
class JabaObjectAPI < APIBase

  ##
  #
  def id
    @obj.id
  end
  
  ##
  # Include one or more shared definitions in this one.
  #
  def include(*shared_definition_ids, args: nil)
    @obj.include_shared(*shared_definition_ids, args: args)
  end

  ##
  #
  def generator(&block)
    @obj.define_generator(&block)
  end
  
  ##
  #
  def method_missing(attr_id, *args, **key_value_args, &block)
    @obj.handle_attr(attr_id, true, *args, **key_value_args, &block)
  end
  
end

end
