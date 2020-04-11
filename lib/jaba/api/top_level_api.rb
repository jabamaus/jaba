# frozen_string_literal: true

module JABA

  ##
  #
  class TopLevelAPI < BasicObject
    
    ##
    # Define a project.
    #
    def project(id, **options, &block)
      @services.define_instance(:project, id, **options, &block)
    end
    
    ##
    # Define a workspace.
    #
    def workspace(id, **options, &block)
      @services.define_instance(:workspace, id, **options, &block)
    end
    
    ##
    # Define a category.
    #
    def category(id, **options, &block)
      @services.define_instance(:category, id, **options, &block)
    end
    
    ##
    # Define definition to be included by other definitions.
    #
    def shared(id, **options, &block)
      @services.define_instance(:shared, id, **options, &block)
    end
    
    ##
    #
    def text(id, **options, &block)
      @services.define_instance(:text, id, **options, &block)
    end
    
    ##
    # All undefined methods are treated as defining instances of jaba types.
    #
    def method_missing(type, id, **options, &block)
      @services.define_instance(type, id, **options, &block)
    end
    
    ##
    # EXTENSION API
    #
    def attr_type(id, &block)
      @services.define_attr_type(id, &block)
    end
    
    ##
    # EXTENSION API
    #
    def attr_flag(id)
      @services.define_attr_flag(id)
    end
    
    ##
    # EXTENSION API
    #
    def define(type, **options, &block)
      @services.define_type(type, **options, &block)
    end
    
    ##
    # EXTENSION API
    #
    def open(type, &block)
      @services.open_type(type, &block)
    end
    
    ##
    #
    def initialize(services)
      @services = services
    end
    
    ##
    # Required when running with ruby-debug-ide.
    #
    def to_s
      "#<TopLevelAPI:0x#{__id__}>"
    end

  end
  
end
