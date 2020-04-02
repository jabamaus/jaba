# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class APIBase < BasicObject

    ##
    # Include one or more shared definitions in this one.
    #
    def include(*shared_definition_ids, args: nil)
      @obj.include_shared(shared_definition_ids, args)
    end
    
    ##
    #
    def raise(msg)
      @obj.services.jaba_error(msg)
    end

    ##
    #
    def puts(str)
      ::Kernel.puts(str)
    end
    
    ##
    #
    def print(str)
      ::Kernel.print(str)
    end
    
    ##
    # Internal use only.
    #
    def __set_obj(o)
      @obj = o
    end
    
  end

  require_relative 'extension_api'

  ##
  # API for creating instances of Jaba types.
  #
  class TopLevelAPI < BasicObject
    
    include TopLevelExtensionAPI
    
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
