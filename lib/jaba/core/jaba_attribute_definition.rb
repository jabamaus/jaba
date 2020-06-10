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

    attr_reader :type_id # eg :bool, :string, :file etc
    attr_reader :variant # :single, :array, :hash
    attr_reader :jaba_attr_type # JabaAttributeType object
    attr_reader :jaba_type

    attr_reader :default
    attr_reader :default_block
    attr_reader :flag_options
    attr_reader :referenced_type # Defined and used by reference attribute type but give access here for efficiency
    
    ##
    #
    def initialize(services, definition, type_id, variant, jaba_type)
      super(services, definition, JDL_AttributeDefinition.new(self))
      
      @type_id = type_id
      @variant = variant
      @jaba_type = jaba_type
      @value_options = []
      @jaba_attr_flags = []
      @default_set = false
      @default_block = nil

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

      # If default not specified by the user (single value attributes only), fall back to default for the attribute
      # type, if there is one eg a string would be ''. Skip if the attribute is flagged as :required, in which case
      # the user must supply the value in definitions.
      #
      attr_type_default = @jaba_attr_type.default
      if !attr_type_default.nil? && attr_single? && !default_set? && !has_flag?(:required)
        set_property(:default, attr_type_default)
      end

      # Attributes that are stored as values in a hash have their corresponding key stored in their options. This is
      # used when cloning attributes. Store as __key to indicate it is internal and to stop it clashing with any user
      # defined option.
      #
      if attr_hash?
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
      "#{@defn_id} type=#{@type_id}"
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
        jaba_error("Invalid value option '#{id.inspect_unquoted}' - no options defined.")
      end
      vo = @value_options.find{|v| v.id == id}
      if !vo
        jaba_error("Invalid value option '#{id.inspect_unquoted}'. Valid options: #{@value_options.map{|v| v.id}}")
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
    def attr_single?
      @variant == :single
    end

    ##
    #
    def attr_array?
      @variant == :array
    end

    ##
    #
    def attr_hash?
      @variant == :hash
    end

    ##
    #
    def reference?
      @type_id == :reference
    end
    
    ##
    #
    def pre_property_set(id, incoming)
      case id
      when :flags
        f = incoming
        if !f.symbol?
          jaba_error('Flags must be specified as symbols, eg :flag')
        end
        if @flags.include?(f)
          jaba_warning("Duplicate flag '#{f.inspect_unquoted}' specified")
          return :ignore
        end
        @jaba_attr_flags << @services.get_attribute_flag(f) # check flag exists
      when :flag_options
        f = incoming
        if !f.symbol?
          jaba_error('Flag options must be specified as symbols, eg :option')
        end
        if @flag_options.include?(f)
          jaba_warning("Duplicate flag option '#{f.inspect_unquoted}' specified")
          return :ignore
        end
      end
    end

    ##
    #
    def post_property_set(id, incoming)
      case id
      when :default
        @default_set = true
        @default_block = @default.proc? ? @default : nil

        if !@default_block
          if attr_single? && incoming.is_a?(Enumerable)
            @services.jaba_error("'#{defn_id}' attribute default must be a single value not a #{incoming.class}")
          elsif attr_array? && !incoming.array?
           @services.jaba_error("'#{defn_id}' array attribute default must be an array")
          elsif attr_hash? && !incoming.hash?
            @services.jaba_error("'#{defn_id}' hash attribute default must be a hash")
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
 
      if @default_set && !@default_block
        @services.set_warn_object(self) do
          case @variant
          when :single
            @jaba_attr_type.call_hook(:validate_value, @default, receiver: self)
          when :array
            @default.each do |elem|
              @jaba_attr_type.call_hook(:validate_value, elem, receiver: self)
            end
          when :hash
            @default.each_value do |elem|
              @jaba_attr_type.call_hook(:validate_value, elem, receiver: self)
            end
          end
        end
      end

      @jaba_attr_flags.each do |jaf|
        begin
          @services.set_warn_object(self) do
            jaf.call_hook(:compatibility, receiver: self)
          end
        rescue JDLError => e
          jaba_error("#{jaf.defn_id.inspect} flag is incompatible: #{e.raw_message}")
        end
      end
      
    rescue JDLError => e
      jaba_error("'#{defn_id}' attribute definition failed validation: #{e.raw_message}", callstack: e.backtrace)
    end

  end

end
