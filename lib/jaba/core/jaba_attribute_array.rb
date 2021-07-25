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
      super(attr_def, node, self)
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
    def do_describe
      "'#{@node.defn_id}.#{@attr_def.defn_id}' array attribute"
    end

    ##
    #
    def value(jdl_call_loc = nil)
      @last_call_location = jdl_call_loc if jdl_call_loc
      if !@set
        if @default_block
          values = services.execute_attr_default_block(@node, @default_block)
          at = @attr_def.jaba_attr_type
          return values.map{|e| at.map_value(e)}
        elsif services.in_attr_default_block?
          attr_error("Cannot read uninitialised #{describe}")
        end
      end
      values = @elems.map {|e| e.value(jdl_call_loc)}
      if !@attr_def.node_by_reference? # read only, enforce by freezing, unless value is a node
        values.freeze
      end
      values
    end
    
    ##
    #
    def set(*args, __jdl_call_loc: nil, prefix: nil, postfix: nil, exclude: nil, **keyval_args, &block)
      @last_call_location = __jdl_call_loc if __jdl_call_loc
      
      # It is possible for values to be nil, which happens if no args are passed. This can happen if the user
      # wants to just set some excludes.
      #
      values = if block_given?
        value_from_block(__jdl_call_loc, id: "#{@attr_def.defn_id}[#{@elems.size}]", &block)
      else
        if @attr_def.node_by_value?
          attr_error("Node attributes require a block")
        end
        args.shift
      end

      values = Array(values)

      # If attribute has not been set and there is a default that was specified in block form 'pull' the values in
      # and prepend them to the values passed in. Defaults specified in blocks are handled lazily to allow the default
      # value to make use of other attributes.
      #
      if !@set && @default_block
        default_values = services.execute_attr_default_block(@node, @default_block)
        if !default_values.array?
          attr_error("#{describe} default requires an array not a '#{default_values.class}'")
        end
        values.prepend(*default_values)
      end

      i = 0
      s = values.size
      while i < s
        val = apply_pre_post_fix(prefix, postfix, values[i])
        elem = make_elem(val, *args, add: false, **keyval_args)
        i += 1
        existing = nil
        if !@attr_def.has_flag?(:allow_dupes) && !@attr_def.node_by_value?
          existing = @elems.find{|e| e.raw_value == elem.raw_value}
        end

        if existing
          jaba_warn("When setting #{describe} stripping duplicate value '#{val.inspect_unquoted}'. See previous at #{existing.src_loc.describe}. " \
            "Flag with :allow_dupes to allow.")
        else
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
    #
    def make_elem(val, *args, add: true, **keyval_args)
      e = JabaAttributeElement.new(@attr_def, @node, self)
      e.set(val, *args, __jdl_call_loc: @last_call_location, **keyval_args)
      if add
        @elems << e
      end
      e
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
      make_elem(val, *f_options, validate: false, __resolve_ref: false, **value_options)
    end

    ##
    #
    def apply_pre_post_fix(pre, post, val)
      if pre || post
        if !val.string?
          attr_error("When setting #{describe} prefix/postfix option can only be used with string arrays")
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
      @elems.delete_if do |attr|
        attr.visit_attr(&block) == :delete ? true : false
      end
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
                attr_error("When setting #{describe} exclude regex can only operate on strings")
              end
              val.match(ex)
            else
              ex == val
            end
          end
        end
      end
      if !@attr_def.has_flag?(:no_sort)
        begin
          @elems.stable_sort!
        rescue StandardError
          attr_error("Failed to sort #{describe}. Might be missing <=> operator")
        end
      end
    end
    
  end

end
