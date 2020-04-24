module JABA

  ##
  #
  class TopLevelAPI < BasicObject
    
    ##
    # Define a cpp project.
    #
    def cpp(id, &block)
      @services.define_instance(:cpp, id, &block)
    end
    
    ##
    # Define a workspace.
    #
    def workspace(id, &block)
      @services.define_instance(:workspace, id, &block)
    end
    
    ##
    # Define a category.
    #
    def category(id, &block)
      @services.define_instance(:category, id, &block)
    end
    
    ##
    # Define definition to be included by other definitions.
    #
    def shared(id, &block)
      @services.define_instance(:shared, id, &block)
    end
    
    ##
    #
    def text(id, &block)
      @services.define_instance(:text, id, &block)
    end
    
    ##
    #
    def defaults(type_id, &block)
      @services.define_defaults(type_id, &block)
    end
    
    ##
    # All undefined methods are treated as defining instances of jaba types.
    #
    def method_missing(type, id, &block)
      @services.define_instance(type, id, &block)
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
    def attr_flag(id, &block)
      @services.define_attr_flag(id, &block)
    end
    
    ##
    # EXTENSION API
    #
    def define(type, &block)
      @services.define_type(type, &block)
    end
    
    ##
    # EXTENSION API
    #
    def open(type, &block)
      @services.open_type(type, &block)
    end
    
  private

    ##
    #
    def initialize(services)
      @services = services
    end

    ##
    # For debugging
    #
    def to_s
      @services.to_s
    end

  end
  
end
