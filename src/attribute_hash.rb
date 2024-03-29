module JABA
  HashSentinel = {}.freeze

  class AttributeHash < AttributeBase
    def initialize(attr_def, node)
      super(attr_def, node)
      @hash = {}
      @in_on_set = false
    end

    def to_s = "#{attr_def} {#{@hash.size} elems}" # For debugger

    # Returns a read only hash of key->attribute values. Expensive because it must map attributes to their values.
    def value
      hash = if set?
          @hash.transform_values { |e| e.value }
        elsif attr_def.default_set?
          default_hash = JABA.context.execute_attr_def_block(self, attr_def.default)
          # TODO: validate
          at = attr_def.attr_type
          default_hash.transform_values { |e| at.map_value(e, self) }
        elsif JABA.context.in_attr_def_block?
          outer = JABA.context.outer_attr_def_block_attr
          outer.attr_error("#{outer.describe} default read uninitialised #{describe} - it might need a default value")
        else
          HashSentinel
        end
      hash.freeze # make read only
    end

    def set(*args, **kwargs, &block)
      to_insert = {}
      kt = attr_def.key_type

      if args.empty?
        attr_error("#{describe} requires a key/value eg \"#{attr_def.name} :my_key, 'my value'\"")
      end
      arg = args.shift

      if arg.is_a?(Hash)
        if block_given?
          attr_error("Cannot pass a hash in conjunction with a block")
        end
        arg.each do |key, val|
          Array(kt.map_value_array(key, self)).each do |k|
            to_insert[k] = val
          end
        end
      else
        keys = Array(kt.map_value_array(arg, self))
        val = if block_given?
            value_from_block(&block)
          else
            if args.empty?
              attr_error("#{describe} requires a key/value eg \"#{attr_def.name} :my_key, 'my value'\"")
            end
            args.shift
          end
        keys.each do |k|
          to_insert[k] = val
        end
      end

      # If attribute has not been set and there is a default that was specified in block form 'pull' the values in
      # and merge them into the hash. Defaults specified in blocks are handled lazily to allow the default
      # value to make use of other attributes.
      #
      apply_default

      # Insert key after defaults to enable defaults to be overwritten if desired
      to_insert.each do |k, v|
        insert_key(k, v, *args, **kwargs)
      end

      @set = true
      nil
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

    def each(&block) = @hash.each(&block)

    # Like each but yields value/key instead of key/value. Used in export system when
    # iterating over array/hash attributes.
    def visit_elem(&block)
      @hash.delete_if do |key, elem|
        block.call(elem, key) == :delete ? true : false
      end
    end

    def process_flags; end # nothing yet

    private

    def apply_default(force: false)
      if !set? && attr_def.default_set? && (!attr_def.has_flag?(:overwrite_default) || force)
        dh = JABA.context.execute_attr_def_block(self, attr_def.default)
        if !dh.is_a?(Hash)
          attr_error("#{describe} default requires a hash not a '#{dh.class}'")
        end
        dh.each do |k, v|
          insert_key(k, v)
        end
      end
    end

    def insert_key(key, val, *args, **kwargs)
      if attr_def.on_validate_key
        rescue_on_validate do
          node.eval_jdl(key, &attr_def.on_validate_key)
        end
      end

      attr = @hash[key]
      if attr.nil?
        attr = AttributeElement.new(@attr_def, @node)
        @hash[key] = attr
      end
      attr.set_last_call_location(last_call_location)
      attr.set(val, *args, **kwargs)

      if attr_def.on_set
        # if @in_on_set
        #   JABA.error("Reentrancy detected in #{describe} on_set")
        # end
        # @in_on_set = true
        # @attr_def.call_block_property(:on_set, key, val, receiver: @node)
        # @in_on_set = false
      end
      attr
    end
  end
end
