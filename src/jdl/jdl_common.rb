module  JABA

  ##
  # API that is common to all JDL elements, including JDL_TopLevel
  #
  module JDL_Common

    ##
    #
    def fail(msg)
      JABA.error(msg)
    end

    ##
    #
    def warn(msg)
      @obj.jaba_warn(msg)
    end

    ##
    #
    def print(msg)
      ::Kernel.print(msg)
    end

    ##
    #
    def puts(msg)
      ::Kernel.puts(msg)
    end

    # Hack to fix issues when debugging. When ruby_debug_ide evals certain objects instance variables and they contain
    # references to the JDL Objects it calls methods on it that don't exist (because BasicObject is a blank slate with barely any methods).
    # These method calls then go through to method_missing and are interpreted as instances of jaba types, meaning program
    # state is being changed as a consequence of being debugged. To prevent this, implement nil? and make it raise an error. nil?
    # is the first method ruby_debug_ide calls. The exception prevents further calls and 'BasicObject' is displayed in the debugger.
    #
    if ::JABA.ruby_debug_ide?
      def to_s
        'BasicObject'
      end
      
      def nil?
        ::Kernel.raise to_s
      end

      def local_variables
        []
      end
    end

  end

  ##
  # API that is common to all JDL elements except JDL_TopLevel
  #
  module JDL_Object_Common

    include JDL_Common
    
    ##
    #
    def id
      @obj.defn_id
    end

    ##
    #
    def include(shared_defn_id, *args)
      @obj.include_shared(shared_defn_id, args)
    end

    ##
    # The directory this definition is in.
    #
    def __dir__
      @obj.source_dir
    end

    ##
    # Returns all the ids of all defined instances of the given type. Can be useful when populating choice attribute items.
    # The type must be defined before this is called, which can be achieved by adding a dependency.
    #
    def all_instance_ids(jaba_type_id)
      @obj.services.jdl_top_level_instance_ids(jaba_type_id)
    end

  end

end
