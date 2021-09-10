module JABA

  ##
  #
  class JabaAttributeArray < JabaAttributeBase
    
    ##
    #
    def initialize(attr_def, node)
      super(attr_def, node, self)
      @elems = []
      if attr_def.default_set? && !@default_block
        set(attr_def.default, call_on_set: false)
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
          attr_error("Cannot read uninitialised #{describe} - it might need a default value")
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
    def set(*args, __jdl_call_loc: nil, prefix: nil, postfix: nil, delete: nil, **keyval_args, &block)
      @last_call_location = __jdl_call_loc if __jdl_call_loc
      
      # It is possible for values to be nil, which happens if no args are passed. This can happen if the user
      # wants to remove something from the array
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

      values.each do |val|
        val = apply_pre_post_fix(prefix, postfix, val)

        # Give plugin a chance to custom handle if its a reference. This is used by cpp plugin to custom handle dependencies
        # on 'export only' cpp definitions.
        #
        if type_id == :node_ref && @node.node_manager.plugin.custom_handle_array_reference(self, val)
          next
        end

        elem = make_elem(val, *args, add: false, **keyval_args)
        existing = nil
        if !@attr_def.has_flag?(:allow_dupes) && !@attr_def.node_by_value?
          existing = @elems.find{|e| e.raw_value == elem.raw_value}
        end

        if existing
          jaba_warn("Stripping duplicate '#{val.inspect_unquoted}' from #{describe}. See previous at #{existing.src_loc.describe}. " \
            "Flag with :allow_dupes to allow.")
        else
          @elems << elem
        end
      end
      
      if delete
        to_delete = Array(delete).map{|r| apply_pre_post_fix(prefix, postfix, r)}
        n_elems = @elems.size
        @elems.delete_if do |e|
          to_delete.any? do |d|
            val = e.value
            if d.proc?
              d.call(val)
            elsif d.is_a?(Regexp)
              if !val.string? && !val.symbol?
                attr_error("Deletion using a regex can only operate on strings or symbols")
              end
              val.match(d)
            else
              d == val
            end
          end
        end
        if @elems.size == n_elems
          services.jaba_warn("'#{delete}' did not match any elements - nothing removed")
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
    #
    def process_flags
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
