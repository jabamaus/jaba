# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  # Manages shared data that is common to Attributes instanced from this definition.
  #
  class JabaAttributeDefinition < JabaObject

    include PropertyMethods

    attr_reader :type_id # eg :bool, :file, :path etc
    attr_reader :variant # :single, :array, :hash
    attr_reader :default
    attr_reader :default_is_proc
    attr_reader :jaba_attr_type # JabaAttributeType object
    attr_reader :jaba_type
    attr_reader :keyval_opts
    
    ##
    #
    def initialize(services, definition, type_id, variant, jaba_type)
      super(services, definition, JabaAttributeDefinitionAPI.new(self))
      
      @type_id = type_id
      @variant = variant
      @jaba_type = jaba_type

      define_property(:help)
      define_property(:default)
      define_array_property(:flags)
      define_array_property(:keyval_opts)
      
      define_hook(:validate)
      define_hook(:post_set)
      
      @jaba_attr_type = @services.get_attribute_type(@type_id)
      @jaba_attr_type.call_hook(:init_attr_def, receiver: self)

      if @definition.block
        eval_api_block(&@definition.block)
      end
    end
    
    ##
    #
    def to_s
      "id=#{@definition.id} type=#{@type_id}"
    end

    ##
    #
    def has_flag?(flag)
      @flags.include?(flag)
    end
    
    ##
    #
    def init
      begin
        @jaba_attr_type.call_hook(:validate_attr_def, receiver: self)
      rescue JabaError => e
        jaba_error("'#{definition_id}' attribute definition failed validation: #{e.raw_message}",
                              callstack: [e.backtrace[0], @api_call_line])
      end
      
      if @default
        begin
          @jaba_attr_type.call_hook(:validate_value, @default, receiver: self)
        rescue JabaError => e
          jaba_error("'#{definition_id}' attribute definition failed validation: #{e.raw_message}",
                                callstack: [e.backtrace[0], @api_call_line])
        end
      end
      
      @default_is_proc = @default.is_a?(Proc)
      @default.freeze
      @flags.freeze
    end

  end

end
