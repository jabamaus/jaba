# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaAttributeBase

    attr_reader :node
    attr_reader :attr_def
    attr_reader :api_call_line
    
    ##
    #
    def initialize(services, attr_def, node)
      @services = services
      @attr_def = attr_def
      @node = node
      @api_call_line = nil
      @set = false
      @default = @attr_def.default
      @default_is_block = @attr_def.default_is_block
    end

    ##
    #
    def type_id
      @attr_def.type_id
    end
    
    ##
    #
    def definition_id
      @attr_def.definition.id
    end
    
    ##
    #
    def set?
      @set
    end
    
    ##
    #
    def required?
      @attr_def.has_flag?(:required)
    end
    
    ##
    #
    def get_default
      if @default_is_block
        @node.eval_api_block(&@default)
      else
        @default
      end
    end

  end

  ##
  #
  class JabaAttribute < JabaAttributeBase

    attr_reader :flag_options

    ##
    #
    def initialize(services, attr_def, parent_array, node)
      super(services, attr_def, node)
      @value = nil
      @flag_options = nil
      @keyval_options = nil
      
      # If its not an element of an attribute array, initialize with default value if it has a concrete one
      #
      if !parent_array && !@default.nil? && !@default_is_block
        @value = resolve_reference(@default)
        @set = true
      end
    end
    
    ##
    # For ease of debugging.
    #
    def to_s
      "value=#{@value} #{@attr_def}"
    end

    ##
    # Returns the value of the attribute. If value is a reference to a JabaNode and the call to value() came from user
    # definitions then return the node's attributes rather than the node itself.
    #
    def value(api_call_line = nil)
      if !set?
        get_default
      elsif api_call_line && @value.is_a?(JabaNode)
        @value.attrs_read_only
      else
        @value
      end
    end
    
    ##
    #
    def set(*args, api_call_line: nil, **key_val_args, &block)
      @api_call_line = api_call_line

      # Check for read only if calling from definitions, or if not calling from definitions but from library code,
      # allow setting read only attrs the first time, in order to initialise them.
      #
      if (api_call_line || set?)
        if @attr_def.has_flag?(:read_only)
          @services.jaba_error("'#{@attr_def.definition_id}' attribute is read only")
        end
      end

      @set = true

      value = block_given? ? @node.eval_api_block(&block) : args.shift
      @flag_options = args

      @flag_options.each do |f|
        if !@attr_def.flag_options.include?(f)
          @services.jaba_error("Invalid flag option '#{f.inspect}'. Valid flags are #{@attr_def.flag_options}")
        end
      end

      key_val_args.each_key do |k|
        if !@attr_def.keyval_options.include?(k)
          @services.jaba_error("Invalid keyval option '#{k}'. Valid keys are #{@attr_def.keyval_options}")
        end
      end

      if value.is_a?(Array)
        @services.jaba_error("'#{@attr_def.definition_id}' attribute is not an array so cannot accept one")
      end
      begin
        @attr_def.jaba_attr_type.call_hook(:validate_value, value, receiver: @attr_def)
      rescue JabaDefinitionError => e
        @services.jaba_error("'#{@attr_def.definition_id}' attribute failed validation: #{e.raw_message}", callstack: e.backtrace)
      end

      # Take a deep copy of keyval_options so they are private to this attribute
      #
      @keyval_options = key_val_args.empty? ? {} : Marshal.load(Marshal.dump(key_val_args))
      
      @value = resolve_reference(value)
    end
    
    ##
    #
    def clear
      @value = nil
      d = @attr_def.default
      if !@default_is_block && !d.nil?
        @value = d
      end
    end
    
    ##
    #
    def <=>(other)
      if @value.respond_to?(:casecmp)
        @value.casecmp(other.value)
      else
        @value <=> other.value
      end
    end
    
    ##
    #
    def has_flag_option?(o)
      @flag_options&.include?(o)
    end

    ##
    #
    def get_option_value(key, fail_if_not_found: true)
      @services.jaba_error("option key '#{key}' not found") if !@keyval_options.key?(key)
      @keyval_options[key]
    end

    ##
    #
    def each_value
      yield @value, @flag_options, @keyval_options
    end
    
    ##
    #
    def map!
      @value = yield(@value)
    end
    
    ##
    #
    def process_flags(warn: true)
      # Nothing yet
    end

    private
 
    ##
    #
    def resolve_reference(value)
      return value if @attr_def.type_id != :reference

      # Get the type id of the referenced node
      #
      rt = @attr_def.referenced_type
      
      # Only resolve reference immediately if referencing a different type to this node's type. This is because not all nodes
      # of the same type will have been created by this point whereas nodes of a different type will all have been created
      # due to having been dependency sorted. References to the same type are resolved after all nodes have been created.
      #
      if rt != @node.jaba_type.definition_id
        ref_node = @services.resolve_reference(self, value)

        # Hang the referenced node of this one. It is used in JabaNode#get_attr when searching for readable attributes.
        #
        @node.referenced_nodes << ref_node
        value = ref_node
      end
      value
    end
    
  end

end
