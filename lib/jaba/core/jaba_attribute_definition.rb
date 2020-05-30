# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  ValueOption = Struct.new(:id, :required, :items)

  ##
  # Manages shared data that is common to Attributes instanced from this definition.
  #
  class JabaAttributeDefinition < JabaObject

    include PropertyMethods

    attr_reader :type_id # eg :bool, :file, :path etc
    attr_reader :variant # :single, :array, :hash
    attr_reader :jaba_attr_type # JabaAttributeType object
    attr_reader :jaba_type

    attr_reader :default
    attr_reader :default_is_block
    attr_reader :flag_options
    attr_reader :referenced_type # Defined and used by reference attribute type but give access here for efficiency
    
    ##
    #
    def initialize(services, definition, type_id, variant, jaba_type)
      super(services, definition, JabaAttributeDefinitionAPI.new(self))
      
      @type_id = type_id
      @variant = variant
      @jaba_type = jaba_type
      @value_options = []
      @jaba_attr_flags = []
      @default_set = false
      @default_is_block = false

      define_property(:title)
      define_property(:help)
      define_property(:default)
      define_array_property(:flags)
      define_array_property(:flag_options)
      
      define_hook(:validate)
      
      @jaba_attr_type = @services.get_attribute_type(@type_id)
      
      @services.set_warn_object(self) do
        @jaba_attr_type.call_hook(:init_attr_def, receiver: self)
      end

      if @definition.block
        eval_api_block(&@definition.block)
      end

      # Attributes that are stored as values in a hash have their corresponding key stored in their options. This is
      # used when cloning attributes. Store as __key to indicate it is internal and to stop it clashing with any user
      # defined option.
      #
      if @variant == :hash
        add_value_option(:__key, false, [])
      end

      validate
      
      @title.freeze
      @help.freeze
      @default.freeze
      @flags.freeze
      @flag_options.freeze
      @value_options.freeze
      @jaba_attr_flags.freeze
    end
    
    ##
    #
    def to_s
      "#{@definition.id} type=#{@type_id}"
    end

    ##
    #
    def add_value_option(id, required, items)
      if !id.symbol?
        jaba_error('value_option id must be specified as a symbol, eg :option')
      end
      @value_options << ValueOption.new(id, required, items).freeze
    end

    ##
    #
    def get_value_option(id)
      if @value_options.empty?
        jaba_error("Invalid value option '#{id.inspect}' - no options defined.")
      end
      vo = @value_options.find{|v| v.id == id}
      if !vo
        jaba_error("Invalid value option '#{id.inspect}'. Valid options: #{@value_options.map{|v| v.id}}")
      end
      vo
    end

    ##
    #
    def each_value_option(&block)
      @value_options.each(&block)
    end
    
    ##
    #
    def has_flag?(flag)
      @flags.include?(flag)
    end
    
    ##
    #
    def default_set?
      @default_set
    end

    ##
    #
    def on_property_set(id, new_val)
      case id
      when :default
        @default_set = true
        @default_is_block = @default.proc?
        if @variant == :single && !@default_is_block
          if new_val.is_a?(Array)
            @services.jaba_error("'#{definition_id}' attribute is not an array so cannot accept one")
          end
        end
      when :flags
        new_val.each do |f|
          if !f.symbol?
            jaba_error('Flags must be specified as symbols, eg :flag')
          end
          @jaba_attr_flags << @services.get_attribute_flag(f) # check flag exists
        end
      when :flag_options
        new_val.each do |f|
          if !f.symbol?
            jaba_error('Flag options must be specified as symbols, eg :option')
          end
        end
      end
    end

    ##
    #
    def validate
      @services.set_warn_object(self) do
        @jaba_attr_type.call_hook(:post_init_attr_def, receiver: self)
      end
 
      if @default_set && !@default_is_block
        @services.set_warn_object(self) do
          @jaba_attr_type.call_hook(:validate_value, @default, receiver: self)
        end
      end

      # TODO: check for duplicate attr flags
      @jaba_attr_flags.each do |jaf|
        begin
          @services.set_warn_object(self) do
            jaf.call_hook(:compatibility, receiver: self)
          end
        rescue JabaDefinitionError => e
          jaba_error("#{jaf.definition_id.inspect} flag is incompatible: #{e.raw_message}")
        end
      end
      
    rescue JabaDefinitionError => e
      jaba_error("'#{definition_id}' attribute definition failed validation: #{e.raw_message}", callstack: e.backtrace)
    end

  end

end
