module JABA

  ##
  #
  class JDL_TopLevel < BasicObject
    
    ##
    # Include another .jaba file or directory containing .jaba files.
    #
    def include(path)
      @services.include_jaba_path(path, base: :jaba_file)
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
    def shared(id=nil, &block)
      @services.define_shared(id, &block)
    end
    
    ##
    #
    def defaults(id=nil, &block)
      @services.define_defaults(id, &block)
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
    def method_missing(type_id=nil, id=nil, *flags, &block)
      @services.define_instance(type_id, id, flags, &block)
    end
    
    ##
    # EXTENSION API
    #
    def type(id=nil, &block)
      @services.define_type(id, &block)
    end
    
    ##
    # EXTENSION API
    #
    def open_type(id=nil, &block)
      @services.open(:type, id, nil, &block)
    end

    ##
    # EXTENSION API
    #
    def open_instance(id=nil, type:, &block)
      @services.open(:instance, id, type, &block)
    end

    ##
    # EXTENSION API
    #
    def open_globals(&block)
      @services.open(:instance, :globals, :globals, &block)
    end

    ##
    # EXTENSION API
    #
    def translator(id=nil, &block)
      @services.define_translator(id, &block)
    end
    
    ##
    # EXTENSION API
    #
    def open_translator(id=nil, &block)
      @services.open(:translator, id, &block)
    end

    ##
    # EXTENSION API
    #
    def open_shared(id=nil, &block)
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
