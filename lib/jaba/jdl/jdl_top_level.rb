module JABA

  ##
  #
  class JDL_TopLevel < BasicObject
    
    ##
    # Include another jdl file.
    #
    def include(filename)
      @services.include_jdl_file(filename)
    end

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
      @services.define_shared(id, &block)
    end
    
    ##
    #
    def text(id, &block)
      @services.define_instance(:text, id, &block)
    end
    
    ##
    #
    def defaults(id, &block)
      @services.define_defaults(id, &block)
    end
    
    ##
    # All undefined methods are treated as defining instances of jaba types.
    #
    def method_missing(type_id, id, &block)
      @services.define_instance(type_id, id, &block)
    end
    
    ##
    # EXTENSION API
    #
    def type(id, &block)
      @services.define_type(id, &block)
    end
    
    ##
    # EXTENSION API
    #
    def open_type(id, &block)
      @services.open(:type, id, nil, &block)
    end

    ##
    # EXTENSION API
    #
    def open_instance(id, type:, &block)
      @services.open(:instance, id, type, &block)
    end

    ##
    # EXTENSION API
    #
    def translator(id, &block)
      @services.define_translator(id, &block)
    end
    
    ##
    # EXTENSION API
    #
    def open_translator(id, &block)
      @services.open(:translator, id, &block)
    end

    ##
    # EXTENSION API
    #
    def open_shared(id, &block)
      @services.open(:shared, id, &block)
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
