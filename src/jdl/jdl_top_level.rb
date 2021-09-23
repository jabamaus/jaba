module JABA

  ##
  #
  class JDL_TopLevel < BasicObject
    
    include JDL_Common

    ##
    # Include another .jaba file or directory containing .jaba files.
    #
    def include(...)
      @load_manager.process_include(:jaba_file, ...)
    end

    ##
    #
    def on_included(&block)
      @load_manager.on_included(::Kernel.caller_locations(1, 1)[0], &block)
    end

    ##
    # Include a jaba file or files from jaba's grab bag.
    #
    def grab(...)
      @load_manager.process_include(:grab_bag, ...)
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
      @file_manager.jdl_glob(pattern, &block)
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
    def initialize(services, load_manager, file_manager)
      @services = services
      @load_manager = load_manager
      @file_manager = file_manager
    end

    ##
    # Assist ruby with constant lookup. Needed when type plugins are declared inline in jaba files and the implementation uses standard ruby classes.
    #
    def self.const_missing(name)
      ::Object.const_get(name)
    end

  end
  
end
