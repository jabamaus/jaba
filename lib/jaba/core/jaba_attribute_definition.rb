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
    attr_reader :flag_options
    attr_reader :keyval_options
    
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
      define_array_property(:flag_options)
      define_array_property(:keyval_options)
      
      define_hook(:validate)
      define_hook(:post_set)
      
      @jaba_attr_type = @services.get_attribute_type(@type_id)
      @jaba_attr_type.call_hook(:init_attr_def, receiver: self)

      if @definition.block
        eval_api_block(&@definition.block)
      end

      @default_is_proc = @default.is_a?(Proc)

      validate

      @help.freeze
      @default.freeze
      @flags.freeze
      @flag_options.freeze
      @keyval_options.freeze
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
    def on_property_set(id, new_val)
      case id
      when :flags
        new_val.each do |f|
          if !f.is_a?(Symbol)
            jaba_error('Flags must be specified as symbols, eg :flag')
          end
          @services.get_attribute_flag(f) # check flag exists
        end
      when :flag_options
        new_val.each do |f|
          if !f.is_a?(Symbol)
            jaba_error('Flag options must be specified as symbols, eg :option')
          end
        end
      when :keyval_options
        new_val.each do |f|
          if !f.is_a?(Symbol)
            jaba_error('Keyval options must be specified as symbols, eg :option')
          end
        end
      end
    end

    ##
    #
    def validate
      begin
        @jaba_attr_type.call_hook(:validate_attr_def, receiver: self)
      rescue JabaDefinitionError => e
        jaba_error("'#{definition_id}' attribute definition failed validation: #{e.raw_message}",
                              callstack: [e.backtrace[0], @api_call_line])
      end
      
      if @default && !@default_is_proc
        begin
          @jaba_attr_type.call_hook(:validate_value, @default, receiver: self)
        rescue JabaDefinitionError => e
          jaba_error("'#{definition_id}' attribute definition failed validation: #{e.raw_message}",
                                callstack: [e.backtrace[0], @api_call_line])
        end
      end
    end

  end

end
