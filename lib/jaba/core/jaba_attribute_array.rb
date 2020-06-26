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
    def initialize(attr_def, node)
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
    # Used in error messages.
    #
    def describe
      "'#{@attr_def.defn_id}' array attribute"
    end

    ##
    #
    def value(api_call_loc = nil)
      @last_call_location = api_call_loc if api_call_loc
      if !@set
        if @default_block
          values = services.execute_attr_default_block(@node, @default_block)
          at = @attr_def.jaba_attr_type
          return values.map{|e| at.map_value(e)}
        elsif services.in_attr_default_block?
          jaba_error("Cannot read uninitialised #{describe}")
        end
      end
      values = @elems.map {|e| e.value(api_call_loc)}
      if !@attr_def.reference? # read only, enforce by freezing, unless value is a node
        values.freeze
      end
      values
    end
    
    ##
    #
    def set(*args, __api_call_loc: nil, prefix: nil, postfix: nil, exclude: nil, **keyval_args, &block)
      @last_call_location = __api_call_loc if __api_call_loc
      
      # It is possible for values to be nil, which happens if no args are passed. This can happen if the user
      # wants to just set some excludes.
      #
      values = block_given? ? @node.eval_jdl(&block) : args.shift

      if values && !values.array?
        jaba_error("#{describe} requires an array not a '#{values.class}'")
      end

      values = Array(values)

      # If attribute has not been set and there is a default that was specified in block form 'pull' the values in
      # and prepend them to the values passed in. Defaults specified in blocks are handled lazily to allow the default
      # value to make use of other attributes.
      #
      if !@set && @default_block
        default_values = services.execute_attr_default_block(@node, @default_block)
        if !default_values.array?
          jaba_error("#{describe} default requires an array not a '#{default_values.class}'")
        end
        values.prepend(*default_values)
      end

      values.each do |v|
        existing = nil
        if !@attr_def.has_flag?(:allow_dupes)
          existing = @elems.find{|e| e.value == v}
        end

        if existing
          jaba_warning("When setting #{describe} stripping duplicate value '#{v.inspect_unquoted}'. See previous at #{existing.last_call_loc_basename}. " \
            "Flag with :allow_dupes to allow.")
        else
          elem = JabaAttributeElement.new(@attr_def, @node)
          v = apply_pre_post_fix(prefix, postfix, v)
          elem.set(v, *args, __api_call_loc: __api_call_loc, **keyval_args)
          @elems << elem
        end
      end
      
      if exclude
        Array(exclude).each do |e|
          @excludes << apply_pre_post_fix(prefix, postfix, e)
        end
      end

      @set = true
      nil
    end
    
    ##
    # If the attribute was never set by the user and it has a default specified in block form ensure that the default value
    # is applied. Call set with no args to achieve this.
    #
    def finalise
      if !@set && @default_block
        set
      end
    end

    ##
    # Clone other attribute and append to this array. Other attribute has already been validated and had any reference resolved.
    # just clone raw value and options. Flags will be processed after, eg stripping duplicates.
    #
    def insert_clone(other)
      value_options = other.value_options
      f_options = other.flag_options
      val = Marshal.load(Marshal.dump(other.raw_value))

      elem = JabaAttributeElement.new(@attr_def, @node)
      elem.set(val, *f_options, validate: false, __resolve_ref: false, **value_options)
      
      @elems << elem
    end

    ##
    #
    def apply_pre_post_fix(pre, post, val)
      if pre || post
        if !val.string?
          jaba_error("When setting #{describe} prefix/postfix option can only be used with string arrays")
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
    # TODO: warn if nothing excluded
    def process_flags
      if @excludes
        @elems.delete_if do |e|
          @excludes.any? do |ex|
            val = e.value
            if ex.proc?
              ex.call(val)
            elsif ex.is_a?(Regexp)
              if !val.string?
                jaba_error("When setting #{describe} exclude regex can only operate on strings")
              end
              val.match(ex)
            else
              ex == val
            end
          end
        end
      end
      if !@attr_def.has_flag?(:nosort)
        begin
          @elems.stable_sort!
        rescue StandardError
          jaba_error("Failed to sort #{decribe}. Might be missing <=> operator")
        end
      end
    end
    
  end

end
