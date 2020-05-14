# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeHash < JabaAttributeBase
    
    ##
    #
    def initialize(services, attr_def, node)
      super
      @hash = {}
      if @default && !@default_is_block
        @default.each do |k, v|
          set(k, v)
        end
      end
    end
    
    ##
    # For ease of debugging.
    #
    def to_s
      "Hash (#{@hash.size} elements) #{@attr_def}"
    end

    ##
    #
    def value(api_call_line = nil)
      if @default_is_block && !set?
        @node.eval_api_block(&@default)
      else
        @hash.transform_values {|e| e.value(api_call_line)}
      end
    end
    
    ##
    # TODO: handle overwriting
    def set(*args, api_call_line: nil, prefix: nil, postfix: nil, exclude: nil, **keyvalue_args, &block)
      @api_call_line = api_call_line
      
      # TODO: validate only key passed if block given
      if args.size < 2 && !block_given?
        @services.jaba_error('Hash attribute requires a key and a value')
      end
      
      key = args.shift

      # If block given, use it to evaluate value
      #
      val = block_given? ? @node.eval_api_block(&block) : args.shift

      elem = JabaAttribute.new(@services, @attr_def, @node)
      # v = apply_pre_post_fix(prefix, postfix, v)
      elem.set(val, *args, api_call_line: api_call_line, __key: key, **keyvalue_args)
      @hash[key] = elem
      @set = true
      
      #if exclude
      #  Array(exclude).each do |e|
      #    @excludes << apply_pre_post_fix(prefix, postfix, e)
      #  end
      #end
    end
    
    ##
    #
    def set_to_default
      default = get_default
      if default
        default.each do |k, v|
          set(k, v)
        end
      end
    end

    ##
    # Clone other attribute and add into this hash. Other attribute has already been validated and had any reference resolved.
    # just clone raw value and options. Flags will be processed after, eg stripping duplicates.
    #
    def insert_clone(other)
      kv_options = other.keyval_options
      f_options = other.flag_options
      key = kv_options[:__key]
      val = Marshal.load(Marshal.dump(other.raw_value))

      elem = JabaAttribute.new(@services, @attr_def, @node)
      elem.set(val, *f_options, api_call_line: nil, validate: false, resolve_ref: false, **kv_options)
      
      @hash[key] = elem
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
      @hash.clear
    end
    
    ##
    # TODO: handle if key not there
    def fetch(key)
      @hash[key]
    end
    
    ##
    #
    def visit_attr(&block)
      @hash.each_value{|attr| attr.visit_attr(&block)}
    end

    ##
    #
    def each_value
      @hash.each do |key, attr|
        attr.each_value do |val, flag_options, keyval_options|
          yield key, val, flag_options, keyval_options
        end
      end
    end
    
    ##
    #
    def map_value!(&block)
      @hash.transform_values! {|e| e.map_value!(&block)}
    end
    
    ##
    #
    def process_flags(warn: true)
      # nothing
    end

  end

end
