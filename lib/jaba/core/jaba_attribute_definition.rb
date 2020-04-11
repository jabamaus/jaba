# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  # Manages shared data that is common to Attributes instanced from this definition.
  #
  class JabaAttributeDefinition < JabaObject

    include PropertyMethods

    attr_reader :id
    attr_reader :type # eg :bool, :file, :path etc
    attr_reader :variant # :single, :array, :hash
    attr_reader :type_obj # JabaAttributeType object
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

      @definition_interface = JabaAttributeDefinitionAPI.new(self)

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
    def eval_obj(context)
      @definition_interface
    end

    ##
    #
    def get_default
      @default
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
