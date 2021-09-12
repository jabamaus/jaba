module JABA

  ##
  #
  class JDL_TopLevel < BasicObject
    
    ##
    # Include another .jaba file or directory containing .jaba files.
    #
    def include(path=nil, &block)
      @services.include_jaba_path(path, base: :jaba_file, &block)
    end

    ##
    # Include a jaba file or files from jaba's grab bag.
    #
    def grab(path)
      @services.include_jaba_path(path, base: :grab_bag)
    end

    ##
    # Define definition to be included by other definitions.
    #
    def shared(...)
      @services.define(:shared, ...)
    end
    
    ##
    #
    def defaults(...)
      @services.define(:defaults, ...)
    end
    
    ##
    #
    def glob(pattern, &block)
      @services.glob(pattern, &block)
    end

    ##
    #
    def puts(msg)
      ::Kernel.puts(msg)
    end

    ##
    # All undefined methods are treated as defining instances of jaba types.
    #
    def method_missing(type_id, ...)
      @services.define(:instance, type_id, ...)
    end
    
    ##
    # EXTENSION API
    #
    def type(...)
      @services.define(:type, ...)
    end
    
    ##
    # EXTENSION API
    #
    def open_type(...)
      @services.open(:type, ...)
    end

    ##
    # EXTENSION API
    #
    def open_instance(...)
      @services.open(:instance, ...)
    end

    ##
    # EXTENSION API
    #
    def open_globals(...)
      @services.open(:instance, 'globals|globals', ...)
    end

    ##
    # EXTENSION API
    #
    def translator(...)
      @services.define(:translator, ...)
    end
    
    ##
    # EXTENSION API
    #
    def open_translator(...)
      @services.open(:translator, ...)
    end

    ##
    # EXTENSION API
    #
    def open_shared(...)
      @services.open(:shared, ...)
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
