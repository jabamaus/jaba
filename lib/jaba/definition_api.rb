# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class TopLevelAPI < BasicObject
    
    ##
    # Define a project.
    #
    def project(id, **options, &block)
      @obj.define_instance(:project, id, **options, &block)
    end
    
    ##
    # Define a workspace.
    #
    def workspace(id, **options, &block)
      @obj.define_instance(:workspace, id, **options, &block)
    end
    
    ##
    # Define a category.
    #
    def category(id, **options, &block)
      @obj.define_instance(:category, id, **options, &block)
    end
    
    ##
    # Define definition to be included by other definitions.
    #
    def shared(id, **options, &block)
      @obj.define_instance(:shared, id, **options, &block)
    end
    
    ##
    #
    def text(id, **options, &block)
      @obj.define_instance(:text, id, **options, &block)
    end
    
    ##
    # EXTENSION API
    #
    def attr_type(id, &block)
      @obj.define_attr_type(id, &block)
    end
    
    ##
    # EXTENSION API
    #
    def attr_flag(id)
      @obj.define_attr_flag(id)
    end
    
    ##
    # EXTENSION API
    #
    def define(type, **options, &block)
      @obj.define_type(type, **options, &block)
    end
    
    ##
    # EXTENSION API
    #
    def open(type, &block)
      @obj.open_type(type, &block)
    end
    
    ##
    # Internal use only.
    #
    def method_missing(type, id, **options, &block)
      @obj.define_instance(type, id, **options, &block)
    end
    
    ##
    # Internal use only.
    #
    def __set_obj(o)
      @obj = o
    end
    
  end

end
