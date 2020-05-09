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
      if @default.is_a?(Hash)
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
    def set(value, *args, api_call_line: nil, prefix: nil, postfix: nil, exclude: nil, **keyvalue_args)
      @api_call_line = api_call_line
      
      if args.empty?
        @services.jaba_error('Hash attribute requires a value')
      end
      
      key = value
      val = args.shift

      elem = JabaAttribute.new(@services, @attr_def, self, @node)
      # v = apply_pre_post_fix(prefix, postfix, v)
      elem.set(val, *args, api_call_line: api_call_line, **keyvalue_args)
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
      # nothing
    end

  end

end
