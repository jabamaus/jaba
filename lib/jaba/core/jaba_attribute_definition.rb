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

    attr_reader :type_id # eg :bool, :string, :file etc
    attr_reader :variant # :single, :array, :hash
    attr_reader :jaba_attr_type # JabaAttributeType object
    attr_reader :jaba_attr_key_type # JabaAttributeType object. Used by hash attribute.
    attr_reader :jaba_type

    attr_reader :title
    attr_reader :notes
    attr_reader :examples
    attr_reader :default
    attr_reader :default_block
    attr_reader :flags
    attr_reader :flag_options
    attr_reader :node_type # Defined and used by node_ref/node attribute types but give access here for efficiency
    
    ##
    #
    def initialize(services, defn_id, src_loc, block, type_id, key_type_id, variant, jaba_type)
      super(services, defn_id, src_loc, JDL_AttributeDefinition.new(self))
      
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
      define_hook(:validate_key)
      
      @jaba_attr_type = services.get_attribute_type(@type_id)
      @jaba_attr_key_type = nil

      # Custom hash attribute setup
      #
      if hash?
        case @key_type_id
        when :symbol, :string
          @jaba_attr_key_type = services.get_attribute_type(@key_type_id)
        else
          JABA.error("#{describe} :key_type must be set to either :symbol or :string")
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

      if block
        eval_jdl(&block)
      end

      # If default not specified by the user (single value attributes only), fall back to default for the attribute
      # type, if there is one eg a string would be ''. Skip if the attribute is flagged as :required, in which case
      # the user must supply the value in definitions.
      #
      attr_type_default = @jaba_attr_type.default
      if !attr_type_default.nil? && single? && !default_set? && !has_flag?(:required)
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
      "'#{@defn_id}' #{@variant == :single ? "" : "#{@variant} "}attribute"
    end

    ##
    #
    def add_value_option(id, required, items)
      if !id.symbol?
        JABA.error("In #{describe} value_option id must be specified as a symbol, eg :option")
      end
      @value_options << ValueOption.new(id, required, items).freeze
    end

    ##
    #
    def get_value_option(id)
      if @value_options.empty?
        JABA.error("Invalid value option '#{id.inspect_unquoted}' - no options defined in #{describe}")
      end
      vo = @value_options.find{|v| v.id == id}
      if !vo
        JABA.error("Invalid value option '#{id.inspect_unquoted}'. Valid #{describe} options: #{@value_options.map{|v| v.id}}")
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
    def single?
      @variant == :single
    end

    ##
    #
    def array?
      @variant == :array
    end

    ##
    #
    def hash?
      @variant == :hash
    end

    ##
    #
    def node_by_reference?
      @type_id == :node_ref
    end

    ##
    #
    def node_by_value?
      @type_id == :node
    end
    
    ##
    #
    def pre_property_set(id, incoming)
      case id
      when :flags
        f = incoming
        if !f.symbol?
          JABA.error('Flags must be specified as symbols, eg :flag')
        end
        if @flags.include?(f)
          jaba_warning("Duplicate flag '#{f.inspect_unquoted}' specified in #{describe}")
          return :ignore
        end
        @jaba_attr_flags << services.get_attribute_flag(f) # check flag exists
      when :flag_options
        f = incoming
        if !f.symbol?
          JABA.error('Flag options must be specified as symbols, eg :option')
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

        if single? && incoming.is_a?(Enumerable)
          JABA.error("#{describe} default must be a single value not a '#{incoming.class}'")
        elsif array? && !incoming.array?
          JABA.error("#{describe} default must be an array not a '#{incoming.class}'")
        elsif hash? && !incoming.hash?
          JABA.error("#{describe} default must be a hash not a '#{incoming.class}'")
        end

        call_validators("#{describe} default") do
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
      when :title
        if incoming.size > MAX_TITLE_CHARS
          JABA.error("Title must be #{MAX_TITLE_CHARS} characters or less but was #{incoming.size}")
        end
      end
    end

    ##
    #
    def on_hook_defined(hook)
      case hook
      when :validate_key
        if !hash?
          JABA.error("#{describe} cannot specify 'validate_key' - only supported by hash attributes")
        end
      end
    end

    ##
    #
    def validate
      # Insist on the attribute having a title, unless running unit tests or in barebones mode. Barebones mode
      # is useful for testing little jaba snippets where adding titles would be cumbersome.
      #
      if @title.nil? && !JABA.running_tests? && !services.input.barebones
        JABA.error("#{describe} requires a title")
      end

      call_validators(describe) do
        @jaba_attr_type.post_init_attr_def(self)
  
        @jaba_attr_flags.each do |jaf|
          begin
            jaf.compatible?(self)
          rescue JabaError => e
            JABA.error("'#{jaf.id.inspect_unquoted}' flag is incompatible: #{e.message}")
          end
        end
      end
    end

    ##
    #
    def call_validators(what)
      services.set_warn_object(self) do
        begin
          yield
        rescue JabaError => e
          JABA.error("#{what} failed validation: #{e.message}", callstack: e.backtrace)
        end
      end
    end

  end

end
