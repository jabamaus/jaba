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
  class JabaAttributeDefinition < JDL_Object

    include PropertyMethods

    attr_reader :title
    attr_reader :notes
    attr_reader :examples
    
    attr_reader :type_id # eg :bool, :string, :file etc
    attr_reader :variant # :single, :array, :hash
    attr_reader :jaba_attr_type # JabaAttributeType object
    attr_reader :jaba_attr_key_type # JabaAttributeType object. Used by hash attribute.
    attr_reader :jaba_type

    attr_reader :default
    attr_reader :default_block
    attr_reader :flags
    attr_reader :flag_options
    attr_reader :referenced_type # Defined and used by reference attribute type but give access here for efficiency
    
    ##
    #
    def initialize(definition, type_id, key_type_id, variant, jaba_type)
      super(definition, JDL_AttributeDefinition.new(self))
      
      @type_id = type_id
      @key_type_id = key_type_id # Only used with hash attributes
      @variant = variant
      @jaba_type = jaba_type
      @value_options = []
      @jaba_attr_flags = []
      @default_set = false
      @default_block = nil

      define_property(:title)
      define_array_property(:notes)
      define_array_property(:examples)
      define_property(:default)
      define_array_property(:flags)
      define_array_property(:flag_options)
      
      define_hook(:validate)
      
      @jaba_attr_type = services.get_attribute_type(@type_id)
      @jaba_attr_key_type = nil

      # Custom hash attribute setup
      #
      if attr_hash?
        case @key_type_id
        when :symbol, :string
          @jaba_attr_key_type = services.get_attribute_type(@key_type_id)
        else
          jaba_error("#{describe} :key_type must be set to either :symbol or :string")
        end

        # Attributes that are stored as values in a hash have their corresponding key stored in their options. This is
        # used when cloning attributes. Store as __key to indicate it is internal and to stop it clashing with any user
        # defined option.
        #
        add_value_option(:__key, false, [])
      end
      
      services.set_warn_object(self) do
        @jaba_attr_type.init_attr_def(self)
      end

      if @definition.block
        eval_jdl(&@definition.block)
      end

      # If default not specified by the user (single value attributes only), fall back to default for the attribute
      # type, if there is one eg a string would be ''. Skip if the attribute is flagged as :required, in which case
      # the user must supply the value in definitions.
      #
      attr_type_default = @jaba_attr_type.default
      if !attr_type_default.nil? && attr_single? && !default_set? && !has_flag?(:required)
        set_property(:default, attr_type_default)
      end

      validate
      
      @title.freeze
      @notes.freeze
      @examples.freeze
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
    # Used in error messages.
    #
    def describe
      "'#{@defn_id}' attribute"
    end

    ##
    #
    def add_value_option(id, required, items)
      if !id.symbol?
        jaba_error("In #{describe} value_option id must be specified as a symbol, eg :option")
      end
      @value_options << ValueOption.new(id, required, items).freeze
    end

    ##
    #
    def get_value_option(id)
      if @value_options.empty?
        jaba_error("Invalid value option '#{id.inspect_unquoted}' - no options defined in #{describe}")
      end
      vo = @value_options.find{|v| v.id == id}
      if !vo
        jaba_error("Invalid value option '#{id.inspect_unquoted}'. Valid #{describe} options: #{@value_options.map{|v| v.id}}")
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
          jaba_warning("Duplicate flag '#{f.inspect_unquoted}' specified in #{describe}")
          return :ignore
        end
        @jaba_attr_flags << services.get_attribute_flag(f) # check flag exists
      when :flag_options
        f = incoming
        if !f.symbol?
          jaba_error('Flag options must be specified as symbols, eg :option')
        end
        if @flag_options.include?(f)
          jaba_warning("Duplicate flag option '#{f.inspect_unquoted}' specified in #{describe}")
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
        return if @default_block

        if attr_single? && incoming.is_a?(Enumerable)
          jaba_error("#{describe} default must be a single value not a '#{incoming.class}'")
        elsif attr_array? && !incoming.array?
          jaba_error("#{describe} default must be an array not a '#{incoming.class}'")
        elsif attr_hash? && !incoming.hash?
          jaba_error("#{describe} default must be a hash not a '#{incoming.class}'")
        end

        begin
          services.set_warn_object(self) do
            case @variant
            when :single
              @jaba_attr_type.validate_value(self, @default)
            when :array
              incoming.each do |elem|
                @jaba_attr_type.validate_value(self, elem)
              end
            when :hash
              incoming.each do |key, val|
                @jaba_attr_key_type.validate_value(self, key)
                @jaba_attr_type.validate_value(self, val)
              end
            end
          end
        rescue JDLError => e
          jaba_error("#{describe} default failed validation: #{e.raw_message}", callstack: e.backtrace)
        end
      end
    end

    ##
    #
    def validate
      if @title.nil? && !JABA.running_tests?
        jaba_error("#{describe} requires a title")
      end

      begin
        services.set_warn_object(self) do
          @jaba_attr_type.post_init_attr_def(self)
        end
  
        @jaba_attr_flags.each do |jaf|
          begin
            services.set_warn_object(self) do
              jaf.call_hook(:compatibility, receiver: self)
            end
          rescue JDLError => e
            jaba_error("#{jaf.describe} is incompatible: #{e.raw_message}")
          end
        end
      rescue JDLError => e
        jaba_error("#{describe} failed validation: #{e.raw_message}", callstack: e.backtrace)
      end
    end

  end

end
