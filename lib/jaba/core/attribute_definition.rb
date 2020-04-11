# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class AttributeTypeDefinition < DefinitionObject

    attr_reader :type
    attr_reader :init_attr_def_hook
    attr_reader :validate_attr_def_hook
    attr_reader :validate_value_hook
    
    ##
    #
    def initialize(services, info)
      super(services)
      @type = info.type
      @init_attr_def_hook = nil
      @validate_attr_def_hook = nil
      @validate_value_hook = nil
      eval_definition(&info.block) if info.block
    end

    ##
    # DEFINITION API
    #
    def init_attr_def(&block)
      define_hook(:init_attr_def, &block)
    end
    
    ##
    # DEFINITION API
    #
    def validate_attr_def(&block)
      define_hook(:validate_attr_def, &block)
    end
    
    ##
    # DEFINITION API
    #
    def validate_value(&block)
      define_hook(:validate_value, &block)
    end
    
  end
  
  ##
  # Manages shared data that is common to Attributes instanced from this definition.
  #
  class AttributeDefinition < DefinitionObject

    attr_reader :id
    attr_reader :type # eg :bool, :file, :path etc
    attr_reader :variant # :single, :array, :hash
    attr_reader :type_obj # AttributeType object
    attr_reader :api_call_line
    attr_reader :jaba_type
    attr_reader :keyval_opts
    
    ##
    #
    def initialize(services, id, type, variant, jaba_type, api_call_line)
      super(services)
      @id = id
      @type = type
      @variant = variant
      @jaba_type = jaba_type
      @api_call_line = api_call_line

      @default = nil
      @flags = []
      @help = nil
      @keyval_opts = []
      
      @validate_hook = nil
      @post_set_hook = nil
      @make_handle_hook = nil
      
      @type_obj = @services.get_attribute_type(@type)
      
      if @type_obj.init_attr_def_hook
        eval_definition(&@type_obj.init_attr_def_hook)
      end
    end
    
    ##
    #
    def get_default
      @default
    end
    
    ##
    # DEFINITION API
    #
    # Set help for the attribute. Required.
    #
    def help(val = nil, &block)
      set_var(:help, val, &block)
    end
    
    ##
    # DEFINITION API
    #
    # Set any number of flags to control the behaviour of the attribute.
    #
    def flags(*flags, &block)
      set_var(:flags, flags.flatten, &block)
    end
    
    ##
    # DEFINITION API
    #
    # Set attribute default value. Can be specified as a value or a block.
    #
    def default(val = nil, &block)
      set_var(:default, val, &block)
    end
    
    ##
    # DEFINITION API
    #
    def keyval_options(*options, &block)
      set_var(:keyval_opts, options.flatten, &block)
    end
    
    ##
    # DEFINITION API
    #
    # Called for single value attributes and each element of array attributes.
    #
    def validate(&block)
      define_hook(:validate, &block)
    end
    
    ##
    # DEFINITION API
    #
    def post_set(&block)
      define_hook(:post_set, &block)
    end
    
    ##
    # DEFINITION API
    #
    def make_handle(&block)
      define_hook(:make_handle, &block)
    end
    
    ##
    # DEFINITION API
    #
    def add_property(id, val = nil)
      set_var(id, val)
    end
    
    ##
    #
    def method_missing(id, val = nil)
      handle_property(id, val)
    end

    ##
    #
    def has_flag?(flag)
      @flags.include?(flag)
    end
    
    ##
    #
    def init
      hook = @type_obj.validate_attr_def_hook
      if hook
        begin
          eval_definition(&hook)
        rescue JabaError => e
          @services.jaba_error("'#{id}' attribute definition failed validation: #{e.raw_message}",
                               callstack: [e.backtrace[0], @api_call_line])
        end
      end
      
      if @default
        hook = @type_obj.validate_value_hook
        if hook
          begin
            eval_definition(@default, &hook)
          rescue JabaError => e
            @services.jaba_error("'#{id}' attribute definition failed validation: #{e.raw_message}",
                                 callstack: [e.backtrace[0], @api_call_line])
          end
        end
      end
      
      @default.freeze
      @flags.freeze
      freeze
    end
    
  end

end
