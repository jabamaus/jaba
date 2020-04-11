# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  # Manages shared data that is common to Attributes instanced from this definition.
  #
  class JabaAttributeDefinition < JabaObject

    include PropertyMethods

    attr_reader :id
    attr_reader :type_id # eg :bool, :file, :path etc
    attr_reader :variant # :single, :array, :hash
    attr_reader :default
    attr_reader :jaba_attr_type # JabaAttributeType object
    attr_reader :jaba_type
    attr_reader :keyval_opts
    attr_reader :api_call_line
    
    ##
    #
    def initialize(services, id, type_id, variant, jaba_type, api_call_line)
      super(services, JabaAttributeDefinitionAPI.new(self))
      @id = id
      @type_id = type_id
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
      
      @jaba_attr_type = @services.get_attribute_type(@type_id)
      
      eval_api_block(&@jaba_attr_type.init_attr_def_hook)
    end
    
    ##
    #
    def has_flag?(flag)
      @flags.include?(flag)
    end
    
    ##
    #
    def init
      hook = @jaba_attr_type.validate_attr_def_hook
      if hook
        begin
          eval_api_block(&hook)
        rescue JabaError => e
          @services.jaba_error("'#{id}' attribute definition failed validation: #{e.raw_message}",
                               callstack: [e.backtrace[0], @api_call_line])
        end
      end
      
      if @default
        hook = @jaba_attr_type.validate_value_hook
        if hook
          begin
            eval_api_block(@default, &hook)
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
