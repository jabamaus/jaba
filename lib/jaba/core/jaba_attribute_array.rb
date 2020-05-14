# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

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
    def set(*args, api_call_line: nil, prefix: nil, postfix: nil, exclude: nil, **keyvalue_args, &block)
      @api_call_line = api_call_line
      
      values = block_given? ? @node.eval_api_block(&block) : args.shift

      Array(values).each do |v|
        elem = JabaAttribute.new(@services, @attr_def, self, @node)
        v = apply_pre_post_fix(prefix, postfix, v)
        elem.set(v, *args, api_call_line: api_call_line, **keyvalue_args)
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
    # Clone other attribute and append to this array. Other attribute has already been validated and had any reference resolved.
    # just clone raw value and options. Flags will be processed after, eg stripping duplicates.
    #
    def insert_clone(other)
      kv_options = other.keyval_options
      f_options = other.flag_options
      val = Marshal.load(Marshal.dump(other.raw_value))

      elem = JabaAttribute.new(@services, @attr_def, self, @node)
      elem.set(val, *f_options, api_call_line: nil, validate: false, resolve_ref: false, **kv_options)
      
      @elems << elem
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
    # Returns attribute element at the given index.
    #
    def at(index)
      @elems[index]
    end
    
    ##
    #
    def visit_attr(&block)
      @elems.each{|attr| attr.visit_attr(&block)}
    end

    ##
    #
    def each_value(&block)
      @elems.each {|e| e.each_value(&block)}
    end
    
    ##
    #
    def map_value!(&block)
      @elems.each {|e| e.map_value!(&block)}
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
            @services.jaba_warning("'#{definition_id}' array attribute contains duplicates: #{dupes.map(&:value).inspect}", callstack: api_call_line)
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
