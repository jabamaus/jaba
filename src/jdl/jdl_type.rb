module JABA

  ##
  #
  class JDL_Type < BasicObject

    include JDL_Object_Common

    ##
    # Set title for the type. Required. Will appear in generated reference manual.
    #
    def title(val)
      @jaba_type.set_property(:title, val)
    end

    ##
    # Flag type as singleton.
    #
    def singleton(val)
      @jaba_type.set_property(:singleton, val, __jdl_call_loc: ::Kernel.caller_locations(1, 1)[0])
    end

    ##
    # Add a help note for this type. Multiple can be added. Will appear in generated reference manual.
    #
    def note(val)
      @jaba_type.set_property(:notes, val, __jdl_call_loc: ::Kernel.caller_locations(1, 1)[0])
    end

    ##
    # Define a new attribute.
    #
    def attr(id, type: nil, jaba_type: nil, &block)
      @jaba_type.define_attr(id, :single, type: type, jaba_type: jaba_type, &block)
    end
    
    ##
    # Define a new array attribute.
    #
    def attr_array(id, type: nil, jaba_type: nil, &block)
      @jaba_type.define_attr(id, :array, type: type, jaba_type: jaba_type, &block)
    end
    
    ##
    # Define a new hash attribute.
    #
    def attr_hash(id, type: nil, key_type: nil, jaba_type: nil, &block)
      @jaba_type.define_attr(id, :hash, type: type, key_type: key_type, jaba_type: jaba_type, &block)
    end

    ##
    #
    def dependencies(*deps)
      @jaba_type.set_property(:dependencies, deps, __jdl_call_loc: ::Kernel.caller_locations(1, 1)[0])
    end

    ##
    # EXTENSION API
    #
    def plugin(&block)
      @jaba_type.set_property(:plugin, __jdl_call_loc: ::Kernel.caller_locations(1, 1)[0], &block)
    end

  private
  
    ##
    #
    def initialize(jaba_type)
      @jaba_type = @obj = jaba_type
    end

  end

end
