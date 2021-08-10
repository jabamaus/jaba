##
#
module JABA

  ##
  #
  class JDL_Type < BasicObject

    include JDL_Common

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
      @jaba_type.set_property(:singleton, val)
    end

    ##
    # Add a help note for this type. Multiple can be added. Will appear in generated reference manual.
    #
    def note(val)
      @jaba_type.set_property(:notes, val)
    end

    ##
    # Define a new attribute.
    #
    def attr(id, type: nil, &block)
      @jaba_type.define_attr(id, :single, type: type, &block)
    end
    
    ##
    # Define a new array attribute.
    #
    def attr_array(id, type: nil, &block)
      @jaba_type.define_attr(id, :array, type: type, &block)
    end
    
    ##
    # Define a new hash attribute.
    #
    def attr_hash(id, type: nil, key_type: nil, &block)
      @jaba_type.define_attr(id, :hash, type: type, key_type: key_type, &block)
    end

    ##
    # Define sub type. Useful for grouping attributes.
    #
    def type(id, &block)
      @jaba_type.define_sub_type(id, &block)
    end

    ##
    #
    def open_type(id, &block)
      @jaba_type.open_sub_type(id, &block)
    end
    
    ##
    #
    def dependencies(*deps)
      @jaba_type.top_level_type.set_property(:dependencies, deps)
    end

    private
  
    ##
    #
    def initialize(jaba_type)
      @jaba_type = @obj = jaba_type
    end

  end

end
