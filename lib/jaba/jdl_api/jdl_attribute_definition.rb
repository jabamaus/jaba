module JABA

  ##
  #
  class JDL_AttributeDefinition < BasicObject

    include JDL_Common

    ##
    # Set title of attribute. Required. Will appear in generated reference manual.
    #
    def title(val = nil)
      @attr_def.set_property(:title, val)
    end

    ##
    # Add a help note for the attribute. Multiple can be added. Will appear in generated reference manual.
    #
    def note(val)
      @attr_def.set_property(:notes, val)
    end
    
    ##
    # Add usage example. Will appear in generated reference manual.
    #
    def example(val)
      @attr_def.set_property(:examples, val)
    end

    ##
    # Set any number of flags to control the behaviour of the attribute.
    #
    def flags(*flags)
      @attr_def.set_property(:flags, flags)
    end
    
    ##
    # Set attribute default value. Can be specified as a value or a block.
    #
    def default(val = nil, &block)
      @attr_def.set_property(:default, val, &block)
    end

    ##
    #
    def default_set?
      @attr_def.default_set?
    end
    
    ##
    #
    def flag_options(*options)
      @attr_def.set_property(:flag_options, options)
    end

    ##
    # Specify an option that takes a value.
    #
    # attr :myattr do
    #   value_option :group, required: true, items [:a, :b, :c]
    # end
    # 
    # would be called like this in definitions:
    #
    # myattr 'value', group: :a
    #
    # And the presence of the :group option and its value would be validated.
    #
    def value_option(id, required: false, items: [])
      @attr_def.add_value_option(id, required, items)
    end
    
    ##
    # Called for single value attributes and each element of array attributes.
    #
    def validate(&block)
      @attr_def.set_hook(:validate, &block)
    end
    
    ##
    #
    def define_property(id, val = nil)
      @attr_def.define_property(id, val)
    end

    ##
    #
    def define_array_property(id, val = [])
      @attr_def.define_array_property(id, val)
    end

    ##
    # Returns attribute type id, eg :bool, :string, :choice, :reference, :file etc
    #
    def type
      @attr_def.type_id
    end

    ##
    # Returns :single, :array or :hash
    #
    def variant
      @attr_def.variant
    end

    ##
    #
    def single?
      @attr_def.single?
    end

    ##
    #
    def array?
      @attr_def.array?
    end

    ##
    #
    def hash?
      @attr_def.hash?
    end

    ##
    #
    def has_flag?(flag)
      @attr_def.has_flag?(flag)
    end

    ##
    #
    def method_missing(id, val = nil, &block)
      @attr_def.handle_property(id, val, &block)
    end
    
    private
  
    ##
    #
    def initialize(attr_def)
      @attr_def = @obj = attr_def
    end
    
  end

end
