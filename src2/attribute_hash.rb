module JABA
  class AttributeHash < AttributeBase
    def initialize(attr_def, node)
      super(attr_def, node)
      @hash = {}
      @in_on_set = false
      if attr_def.default_set? && !attr_def.default_is_block?
        attr_def.default.each do |k, v|
          insert_key(k, v, call_on_set: false)
        end
      end
    end

    # For ease of debugging.
    #
    def to_s = "#{attr_def} {#{@hash.size} elems}"

    # Used in error messages.
    #
    def describe = "'#{attr_def.name}' hash attribute"

    # Returns a read only hash of key->attribute values. Expensive because it must map attributes to their values.
    #
    def value
      record_last_call_location
      if !set?
        if attr_def.default_is_block?
          default_hash = JABA.context.execute_attr_default_block(self)
          at = attr_def.attr_type
          return default_hash.transform_values { |e| at.map_value(e, self) }
        elsif JABA.context.in_attr_default_block?
          outer = JABA.context.outer_default_attr_read
          outer.attr_error("#{outer.describe} default read uninitialised #{describe} - it might need a default value")
        end
      end
      values = @hash.transform_values { |e| e.value }
      values.freeze # make read only
    end

    def set(*args,
            __no_keyval: false,
            **kwargs, &block)
      record_last_call_location

      key = val = nil
      if !__no_keyval
        if args.empty?
          attr_error("#{describe} requires a key/value eg \"#{attr_def.name} :my_key, 'my value'\"")
        end
        key = args.shift

        # If block given, use it to evaluate value
        #
        val = if block_given?
            value_from_block(&block)
          else
            if args.empty?
              attr_error("#{describe} requires a key/value eg \"#{attr_def.name} :my_key, 'my value'\"")
            end
            args.shift
          end
      end

      # If attribute has not been set and there is a default that was specified in block form 'pull' the values in
      # and merge them into the hash. Defaults specified in blocks are handled lazily to allow the default
      # value to make use of other attributes.
      #
      if !set? && attr_def.default_is_block?
        default_hash = JABA.context.execute_attr_default_block(self)
        if !default_hash.is_a?(Hash)
          attr_error("#{describe} default requires a hash not a '#{default_hash.class}'")
        end
        default_hash.each do |k, v|
          insert_key(k, v, *args, **kwargs)
        end
      end

      # Insert key after defaults to enable defaults to be overwritten if desired
      #
      if !__no_keyval
        insert_key(key, val, *args, **kwargs)
      end

      @set = true
      nil
    end

    # If the attribute was never set by the user and it has a default specified in block form ensure that the default value
    # is applied. Call set with no args to achieve this.
    #
    def finalise
      if !set? && attr_def.default_is_block?
        set(__no_keyval: true)
      end
    end

    # Clone other attribute and add into this hash. Other attribute has already been validated and had any reference resolved.
    # just clone raw value and options. Flags will be processed after, eg stripping duplicates.
    #
    def insert_clone(other)
      v_options = other.value_options
      f_options = other.flag_options
      key = v_options[:__key]
      val = Marshal.load(Marshal.dump(other.raw_value))
      insert_key(key, val, *f_options, __validate: false, **v_options)
    end

    def clear = @hash.clear

    def fetch(key, fail_if_not_found: true)
      if !@hash.key?(key)
        if fail_if_not_found
          attr_error("'#{key}' key not found in #{describe}")
        else
          return nil
        end
      end
      @hash[key]
    end

    def visit_attr(&block)
      @hash.delete_if do |key, attr|
        attr.visit_attr(&block) == :delete ? true : false
      end
    end

    def process_flags; end # nothing yet

    private

    def insert_key(key, val, *args, __validate: true, __call_on_set: true, **kwargs)
      attr = AttributeElement.new(@attr_def, @node)

      if __validate && attr_def.on_validate_key
        rescue_on_validate do
          node.eval_jdl(key, &attr_def.on_validate_key)
        end
      end

      attr.set(val, *args, __validate: __validate, __key: key, __call_on_set: false, **kwargs)

      if __call_on_set
        # if @in_on_set
        #   JABA.error("Reentrancy detected in #{describe} on_set")
        # end
        # @in_on_set = true
        # @attr_def.call_block_property(:on_set, key, val, receiver: @node)
        # @in_on_set = false
      end

      # Log overwrites. This behaviour could be beefed up and customised with options if necessary
      #
      existing = @hash[key]
      if existing
        if existing.value != val
          JABA.log("Overwriting '#{key}' hash key [old=#{existing.value}, new=#{val}] in #{describe}")
        end
      end
      @hash[key] = attr
      attr
    end
  end
end
