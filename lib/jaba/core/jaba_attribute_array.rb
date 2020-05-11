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
    def set(values, *args, api_call_line: nil, prefix: nil, postfix: nil, exclude: nil, **keyvalue_args)
      @api_call_line = api_call_line
      
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
