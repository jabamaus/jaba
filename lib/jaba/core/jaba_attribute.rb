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
        key.to_s.casecmp(other.key.to_s)
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
      @default_is_proc = @default.is_a?(Proc)
    end

    ##
    # For ease of debugging.
    #
    def to_s
      @attr_def.to_s
    end

    ##
    #
    def type_id
      @attr_def.type_id
    end
    
    ##
    #
    def id
      @attr_def.id
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

    attr_reader :options
    attr_reader :key_value_options
    
    ##
    #
    def initialize(services, attr_def, parent_array, node)
      super(services, attr_def, node)
      @value = nil
      @options = nil
      @key_value_options = nil
      
      # If its not an element of an attribute array, initialize with default value if it has a concrete one
      #
      if !parent_array && !@default.nil? && !@default_is_proc
        validate_value(@default, attr_def.api_call_line)
        @value = resolve_reference(@default)
        @set = true
      end
    end
    
    ##
    #
    def get(api_call_line = nil)
      if !set? && @default_is_proc
        @node.eval_api_block(&@default)
      elsif api_call_line && @value.is_a?(JabaNode)
        @value.id
      else
        @value
      end
    end
    
    ##
    #
    def set(value, api_call_line = nil, *args, **keyvalue_args)
      validate_keyvalue_options(keyvalue_args, api_call_line)
      validate_value(value, api_call_line)

      @api_call_line = api_call_line
      
      # Take deep copies of options so they are private to this attribute
      #
      @options = Marshal.load(Marshal.dump(args))
      @key_value_options = Marshal.load(Marshal.dump(keyvalue_args))
      
      # TODO: fix
      @value = if @attr_def.type_id == :keyvalue
                 KeyValue.new(value, args[0])
                 # TODO: remove args[0] from options
               else
                 resolve_reference(value)
               end
      @set = true
    end
    
    ##
    #
    def clear
      @value = nil
      d = @attr_def.default
      if !d.nil? && !@default_is_proc
        @value = d
      end
    end
    
    ##
    #
    def <=>(other)
      if @value.respond_to?(:casecmp)
        @value.to_s.casecmp(other.get.to_s)
      else
        @value <=> other.get
      end
    end
    
    ##
    #
    def each_value
      yield @value, @options, @key_value_options
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
        @services.jaba_error("'#{@attr_def.id}' attribute is not an array so cannot accept one", callstack: api_call_line)
      end
      if api_call_line
        hook = @attr_def.jaba_attr_type.validate_value_hook
        if hook
          begin
            @attr_def.eval_api_block(value, &hook)
          rescue JabaError => e
            @services.jaba_error("'#{@attr_def.id}' attribute failed validation: #{e.raw_message}", callstack: e.backtrace)
          end
        end
      end
    end
    
    ##
    #
    def validate_keyvalue_options(options, api_call_line)
      options.each_key do |k|
        if !@attr_def.keyval_opts.include?(k)
          @services.jaba_error("Invalid option '#{k}'", callstack: api_call_line)
        end
      end
    end
    
    ##
    #
    def resolve_reference(value)
      if @attr_def.type_id == :reference
        rt = @attr_def.get_property(:referenced_type)
        if rt != @node.jaba_type.type_id
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
    #
    def get(api_call_line = nil)
      if !set? && @default_is_proc
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
        if @elems.uniq!(&:get) && warn
          @services.jaba_warning("'#{id}' array attribute contains duplicates", callstack: api_call_line)
        end
      end
      if !@attr_def.has_flag?(:unordered)
        begin
          @elems.stable_sort!
        rescue StandardError
          @services.jaba_error("Failed to sort #{id}. Might be missing <=> operator", callstack: api_call_line)
        end
      end
    end
    
  end
  
end
