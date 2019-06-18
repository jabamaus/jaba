# frozen_string_literal: true

module JABA

  # The classes in this file are only needed by the user if extending the core functionality of Jaba.

  ##
  #
  module TopLevelExtensionAPI

    ##
    #
    def attr_type(id, &block)
      @obj.define_attr_type(id, &block)
    end
    
    ##
    #
    def attr_flag(id)
      @obj.define_attr_flag(id)
    end
    
    ##
    #
    def define(type, **options, &block)
      @obj.define_type(type, **options, &block)
    end
    
    ##
    #
    def open(type, &block)
      @obj.open_type(type, &block)
    end
    
  end

  ##
  #
  class AttributeTypeAPI < APIBase
    
    ##
    #
    def init_attr_def(&block)
      @obj.define_hook(:init_attr_def, &block)
    end
    
    ##
    #
    def validate_attr_def(&block)
      @obj.define_hook(:validate_attr_def, &block)
    end
    
    ##
    #
    def validate_value(&block)
      @obj.define_hook(:validate_value, &block)
    end
    
  end

  ##
  #
  class JabaTypeAPI < APIBase
    
    ##
    #
    def type
      @obj.type
    end
    
    ##
    # Define a new attribute. See AttributeDefinitionAPI class below.
    #
    def attr(id, **options, &block)
      @obj.define_attr(id, **options, &block)
    end
    
    ##
    #
    def attr_array(id, **options, &block)
      @obj.define_attr(id, array: true, **options, &block)
    end
    
    ##
    #
    def dependencies(*deps)
      @obj.set_var(:dependencies, deps.flatten)
    end

  end

  ##
  #
  class AttributeDefinitionAPI < APIBase

    ##
    # Set help for the attribute. Required.
    #
    def help(val = nil, &block)
      @obj.set_var(:help, val, &block)
    end
    
    ##
    # Set any number of flags to control the behaviour of the attribute.
    #
    def flags(*flags, &block)
      @obj.set_var(:flags, flags.flatten, &block)
    end
    
    ##
    # Set attribute default value. Can be specified as a value or a block.
    #
    def default(val = nil, &block)
      @obj.set_var(:default, val, &block)
    end
    
    ##
    #
    def keyval_options(*options, &block)
     @obj.set_var(:keyval_options, options.flatten, &block)
    end
    
    ##
    # Called for single value attributes and each element of array attributes.
    #
    def validate(&block)
      @obj.define_hook(:validate, &block)
    end
    
    ##
    #
    def post_set(&block)
      @obj.define_hook(:post_set, &block)
    end
    
    ##
    #
    def make_handle(&block)
      @obj.define_hook(:make_handle, &block)
    end
    
    ##
    #
    def add_property(id, val = nil)
      @obj.set_var(id, val)
    end
    
    ##
    #
    def jaba_type
      @obj.jaba_type.api
    end
    
    ##
    #
    def method_missing(id, val = nil)
      @obj.handle_property(id, val)
    end

  end

end
