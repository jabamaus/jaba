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
      @default_is_proc = @attr_def.default_is_proc
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
    def process_flags(warn: true)
      # Nothing
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
      if !parent_array && !@default.nil? && !@default_is_proc
        validate_value(@default, attr_def.api_call_line)
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
    # TODO: rename to 'value'
    def get(api_call_line = nil)
      if @default_is_proc && !set?
        @node.eval_api_block(&@default)
      elsif api_call_line && @value.is_a?(JabaNode)
        @value.definition_id
      else
        @value
      end
    end
    
    ##
    #
    def set(value, api_call_line = nil, *args, **key_val_args)
      @api_call_line = api_call_line

      if @attr_def.type_id == :keyvalue
        value = KeyValue.new(value, args.shift)
      end

      @flag_options = args

      @flag_options.each do |f|
        if !@attr_def.flag_options.include?(f)
          @services.jaba_error("Invalid flag option '#{f.inspect}'. Valid flags are #{@attr_def.flag_options}", callstack: api_call_line)
        end
      end

      key_val_args.each_key do |k|
        if !@attr_def.keyval_options.include?(k)
          @services.jaba_error("Invalid keyval option '#{k}'. Valid keys are #{@attr_def.keyval_options}", callstack: api_call_line)
        end
      end

      validate_value(value, api_call_line)

      # Take a deep copy of keyval_options so they are private to this attribute
      #
      @keyval_options = key_val_args.empty? ? {} : Marshal.load(Marshal.dump(key_val_args))
      
      @value = resolve_reference(value)
      @set = true
    end
    
    ##
    #
    def clear
      @value = nil
      d = @attr_def.default
      if !@default_is_proc && !d.nil?
        @value = d
      end
    end
    
    ##
    #
    def <=>(other)
      if @value.respond_to?(:casecmp)
        @value.casecmp(other.get)
      else
        @value <=> other.get
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
      raise "option key '#{key}' not found" if !@keyval_options.key?(key)
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
    
    private
    
    ##
    #
    def validate_value(value, api_call_line)
      if value.is_a?(Array)
        @services.jaba_error("'#{@attr_def.definition_id}' attribute is not an array so cannot accept one", callstack: api_call_line)
      end
      if api_call_line
        begin
          @attr_def.jaba_attr_type.call_hook(:validate_value, value, receiver: @attr_def)
        rescue JabaError => e
          @services.jaba_error("'#{@attr_def.definition_id}' attribute failed validation: #{e.raw_message}", callstack: e.backtrace)
        end
      end
    end
    
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
    def get(api_call_line = nil)
      if @default_is_proc && !set?
        @node.eval_api_block(&@default)
      else
        @elems.map {|e| e.get(api_call_line)}
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
          @services.jaba_error('prefix/postfix option can only be used with arrays of strings', callstack: api_call_line)
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
            val = e.get
            if ex.is_a?(Proc)
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
        if warn && @elems.uniq!(&:get)
          @services.jaba_warning("'#{definition_id}' array attribute contains duplicates", callstack: api_call_line)
        end
      end
      if !@attr_def.has_flag?(:unordered)
        begin
          @elems.stable_sort!
        rescue StandardError
          @services.jaba_error("Failed to sort #{definition_id}. Might be missing <=> operator", callstack: api_call_line)
        end
      end
    end
    
  end
  
end
