# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  # Maximum length of attribute etc title string.
  #
  MAX_TITLE_CHARS = 100

  ##
  # Manages shared data that is common to Attributes instanced from this definition.
  #
  class JabaAttributeDefinition < JabaObject

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
    attr_reader :on_set
    
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
      @in_eval_block = false

      define_property(:title)
      define_array_property(:notes)
      define_array_property(:examples)
      define_property(:default, variant: variant, store_block: true)
      define_array_property(:flags)
      define_array_property(:flag_options)
      
      define_block_property(:validate)
      define_block_property(:validate_key)
      define_block_property(:on_set)
      
      @jaba_attr_type = services.get_attribute_type(@type_id)
      @jaba_attr_key_type = nil
      

      # Custom hash attribute setup
      #
      if hash?
        if @key_type_id
          @jaba_attr_key_type = services.get_attribute_type(@key_type_id)
        else
          JABA.error("#{describe} must specify :key_type [#{services.jaba_attr_types.map{|t| t.id.inspect}.join(', ')}]")
        end

        # Attributes that are stored as values in a hash have their corresponding key stored in their options. This is
        # used when cloning attributes. Store as __key to indicate it is internal and to stop it clashing with any user
        # defined option.
        #
        add_value_option(:__key, false, [])
      end
      
      @jaba_attr_type.init_attr_def(self)

      if block
        @in_eval_block = true
        eval_jdl(&block)
        @in_eval_block = false
      end

      # Allow attribute definition flag specs to modify attr def, eg the :exportable flag adds the
      # :export and :export_ony options.
      #
      @jaba_attr_flags.each do |jaf|
        jaf.init_attr_def(self)
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

    ValueOption = Struct.new(
      :id,
      :required,
      :items
    )

    ##
    #
    def add_value_option(id, required, items)
      if !id.symbol?
        JABA.error("In #{describe} value_option id must be specified as a symbol, eg :option")
      end
      vo = ValueOption.new
      vo.id = id
      vo.required = required
      vo.items = items
      vo.freeze
      @value_options << vo
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
    def block_attr?
      @type_id == :block
    end
    
    ##
    # Special case handling to try and catch the attribute definition writer from trying to read an attribute when setting a default
    # value directly (ie without using a block), eg
    #
    # default "#{my_path_attribute}/#{my_name_ttribute}"
    #
    # This will actually attempt to read a property called my_attribute and would give a potentially confusing message that the
    # property is not defined. The solution is to put the default in a block, which is evaluated later, eg
    #
    # default do
    #   "#{my_path_attribute}/#{my_name_ttribute}"
    # end
    #
    def handle_property(p_id, val, &block)
      if val.nil? && !block_given? && @in_eval_block && !property_defined?(p_id)
        JABA.error("'#{defn_id}.#{p_id}' undefined. Are you setting default in terms of another attribute? If so block form must be used")
      else
        super
      end
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
          jaba_warn("Duplicate flag '#{f.inspect_unquoted}' specified in #{describe}")
          return :ignore
        end
        jaf = services.get_attribute_flag(f) # check flag exists
        jaf.compatible?(self)
        @jaba_attr_flags << jaf
      when :flag_options
        f = incoming
        if !f.symbol?
          JABA.error('Flag options must be specified as symbols, eg :option')
        end
        if @flag_options.include?(f)
          jaba_warn("Duplicate flag option '#{f.inspect_unquoted}' specified in #{describe}")
          return :ignore
        end
      when :validate_key
        if !hash?
          JABA.error("#{describe} cannot specify 'validate_key' - only supported by hash attributes")
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

        call_validators("#{describe} default") do
          case @variant
          when :single, :array
            @jaba_attr_type.validate_value(self, incoming)
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
    def validate
      call_validators(describe) do

        # Insist on the attribute having a title, unless running unit tests or in barebones mode. Barebones mode
        # is useful for testing little jaba snippets where adding titles would be cumbersome.
        #
        if @title.nil? && !JABA.running_tests? && !services.input.barebones
          JABA.error('requires a title')
        end

        @jaba_attr_type.post_init_attr_def(self)
      end
    end

    ##
    #
    def call_validators(what)
      begin
        yield
      rescue => e
        JABA.error("#{what} invalid: #{e.message}", callstack: e.backtrace)
      end
    end

  end

end
