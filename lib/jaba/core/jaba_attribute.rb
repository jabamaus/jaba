# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  KeyValue = Struct.new(:key, :value) do
    def <=>(other)
      if key.respond_to?(:casecmp)
        key.casecmp(other.key)
      else
        key <=> other.key
      end
    end
  end
  
  ##
  #
  class JabaAttributeBase

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
    # Returns the value of the attribute.
    #
    def value(api_call_line = nil)
      if !set?
        get_default
      elsif api_call_line && @value.is_a?(JabaNode)
        @value.attrs
      else
        @value
      end
    end
    
    ##
    #
    def set(value, api_call_line = nil, *args, **key_val_args)
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

      return if value.nil?

      if @attr_def.type_id == :keyvalue
        if args.empty?
          #@services.jaba_error("keyvalue attribute requires a value")
        end
        value = KeyValue.new(value, args.shift)
      end

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
      if @attr_def.type_id == :reference
        rt = @attr_def.get_property(:referenced_type)
        if rt != @node.jaba_type.definition_id
          ref_node = @services.node_from_handle("#{rt}|#{value}")
          @node.referenced_nodes << ref_node
          ref_node
        else
          value
        end
      else
        value
      end
    end
    
  end

  ##
  #
  class JabaAttributeArray < JabaAttributeBase
    
    ##
    #
    def initialize(services, attr_def, node)
      super
      @elems = []
      @excludes = []
      if @default.is_a?(Array)
        set(@default)
      end
    end
    
    ##
    # For ease of debugging.
    #
    def to_s
      "Array (#{@elems.size} elements) #{@attr_def}"
    end

    ##
    #
    def value(api_call_line = nil)
      if @default_is_block && !set?
        @node.eval_api_block(&@default)
      else
        @elems.map {|e| e.value(api_call_line)}
      end
    end
    
    ##
    #
    def set(values, api_call_line = nil, *args, prefix: nil, postfix: nil, exclude: nil, **keyvalue_args)
      @api_call_line = api_call_line
      
      Array(values).each do |v|
        elem = JabaAttribute.new(@services, @attr_def, self, @node)
        v = apply_pre_post_fix(prefix, postfix, v)
        elem.set(v, api_call_line, *args, **keyvalue_args)
        @elems << elem
        @set = true
      end
      
      if exclude
        Array(exclude).each do |e|
          @excludes << apply_pre_post_fix(prefix, postfix, e)
        end
      end
    end
    
    ##
    #
    def apply_pre_post_fix(pre, post, val)
      if pre || post
        if !val.is_a?(String)
          @services.jaba_error('prefix/postfix option can only be used with arrays of strings')
        end
        "#{pre}#{val}#{post}"
      else
        val
      end
    end
    
    ##
    #
    def clear
      @elems.clear
    end
    
    ##
    #
    def get_elem(i)
      @elems[i]
    end
    
    ##
    #
    def each(&block)
      @elems.each(&block)
    end
    
    ##
    #
    def each_value(&block)
      @elems.each {|e| e.each_value(&block)}
    end
    
    ##
    #
    def map!(&block)
      @elems.each {|e| e.map!(&block)}
    end
    
    ##
    #
    def process_flags(warn: true)
      if @excludes
        @elems.delete_if do |e|
          @excludes.any? do |ex|
            val = e.value
            if ex.is_a_block?
              ex.call(val)
            elsif ex.is_a?(Regexp)
              if !val.is_a?(String)
                @services.jaba_error('exclude regex can only operate on strings', callstack: e.api_call_line)
              end
              val.match(ex)
            else
              ex == val
            end
          end
        end
      end
      if !@attr_def.has_flag?(:allow_dupes)
        if warn
          dupes = @elems.uniq!(&:value)
          if dupes
            # TODO: report dupes
            @services.jaba_warning("'#{definition_id}' array attribute contains duplicates", callstack: api_call_line)
          end
        end
      end
      if !@attr_def.has_flag?(:unordered)
        begin
          @elems.stable_sort!
        rescue StandardError
          @services.jaba_error("Failed to sort #{definition_id}. Might be missing <=> operator")
        end
      end
    end
    
  end
  
end
