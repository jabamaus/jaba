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
      if attr_def.default_set? && !@default_block
        set(attr_def.default)
      end
    end
    
    ##
    # For ease of debugging.
    #
    def to_s
      "#{@attr_def} [#{@elems.size} elems]"
    end

    ##
    #
    def value(api_call_line = nil)
      if !@set
        if @default_block
          return @services.execute_attr_default_block(@node, @default_block)
        elsif @services.in_attr_default_block?
          @services.jaba_error("Cannot read uninitialised '#{definition_id}' attribute")
        end
      end
      @elems.map {|e| e.value(api_call_line)}.freeze  # read only, enforce by freezing
    end
    
    ##
    #
    def set(*args, api_call_line: nil, prefix: nil, postfix: nil, exclude: nil, **keyvalue_args, &block)
      @last_call_location = api_call_line
      @set = true
      
      values = block_given? ? @node.eval_api_block(&block) : args.shift

      Array(values).each do |v|
        elem = JabaAttributeElement.new(@services, @attr_def, @node)
        v = apply_pre_post_fix(prefix, postfix, v)
        elem.set(v, *args, api_call_line: api_call_line, **keyvalue_args)
        @elems << elem
      end
      
      if exclude
        Array(exclude).each do |e|
          @excludes << apply_pre_post_fix(prefix, postfix, e)
        end
      end
    end
    
    ##
    # If attribute's default value was specified as a block it is executed here, after the node has been created, since
    # default blocks can be implemented in terms of other attributes. Note that the default block is always executed regardless
    # of whether the user added array elements as the behaviour of array attributes is to always append.
    #
    def finalise
      return if !@default_block
      val = @services.execute_attr_default_block(@node, @default_block)
      set(val)
    end

    ##
    # Clone other attribute and append to this array. Other attribute has already been validated and had any reference resolved.
    # just clone raw value and options. Flags will be processed after, eg stripping duplicates.
    #
    def insert_clone(other)
      value_options = other.value_options
      f_options = other.flag_options
      val = Marshal.load(Marshal.dump(other.raw_value))

      elem = JabaAttributeElement.new(@services, @attr_def, @node)
      elem.set(val, *f_options, api_call_line: nil, validate: false, resolve_ref: false, **value_options)
      
      @elems << elem
    end

    ##
    #
    def apply_pre_post_fix(pre, post, val)
      if pre || post
        if !val.string?
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
    def process_flags
      if @excludes
        @elems.delete_if do |e|
          @excludes.any? do |ex|
            val = e.value
            if ex.proc?
              ex.call(val)
            elsif ex.is_a?(Regexp)
              if !val.string?
                @services.jaba_error('exclude regex can only operate on strings', callstack: e.last_call_location)
              end
              val.match(ex)
            else
              ex == val
            end
          end
        end
      end
      if !@attr_def.has_flag?(:allow_dupes)
        dupes = @elems.remove_and_return_dupes(by: :value)
        if dupes
          @services.jaba_warning("'#{definition_id}' array attribute contains duplicates: #{dupes.inspect}", callstack: last_call_location)
        end
      end
      if !@attr_def.has_flag?(:nosort)
        begin
          @elems.stable_sort!
        rescue StandardError
          @services.jaba_error("Failed to sort #{definition_id}. Might be missing <=> operator")
        end
      end
    end
    
  end

end
