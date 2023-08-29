module JABA

  class JabaAttributeHash < JabaAttributeBase

    def initialize(attr_def, node)
      super(attr_def, node, self)
      @hash = {}
      @in_on_set = false
      if attr_def.default_set? && !@default_block
        attr_def.default.each do |k, v|
          insert_key(k, v, call_on_set: false)
        end
      end
    end
    
    # For ease of debugging.
    #
    def to_s = "#{@attr_def} {#{@hash.size} elems}"

    # Used in error messages.
    #
    def do_describe = "'#{@node.defn_id}.#{@attr_def.defn_id}' hash attribute"

    # Returns a read only hash of key->attribute values. Expensive because it must map attributes to their values.
    #
    def value(jdl_call_loc = nil)
      @last_call_location = jdl_call_loc if jdl_call_loc
      if !@set
        if @default_block
          default_hash = services.execute_attr_default_block(@node, @default_block)
          at = @attr_def.jaba_attr_type
          return default_hash.transform_values{|e| at.map_value(e)}
        elsif services.in_attr_default_block?
          attr_error("Cannot read uninitialised #{describe} - it might need a default value")
        end
      end
      values = @hash.transform_values {|e| e.value(jdl_call_loc)}
      if !@attr_def.reference? # read only, enforce by freezing, unless value is a node
        values.freeze
      end
      values
    end
    
    def set(*args, no_keyval: false, __jdl_call_loc: nil, **keyval_args, &block)
      @last_call_location = __jdl_call_loc if __jdl_call_loc
      
      key = val = nil
      if !no_keyval
        if args.empty?
          attr_error("#{describe} requires a key/value eg \"#{defn_id} :my_key, 'my value'\"")
        end
        key = args.shift

        # If block given, use it to evaluate value
        #
        val = if block_given?
          value_from_block(__jdl_call_loc, id: "#{@attr_def.defn_id}|#{key}", block_args: key, &block)
        else
          if args.empty?
            attr_error("#{describe} requires a key/value eg \"#{defn_id} :my_key, 'my value'\"")
          end
          args.shift
        end
      end

      # If attribute has not been set and there is a default that was specified in block form 'pull' the values in
      # and merge them into the hash. Defaults specified in blocks are handled lazily to allow the default
      # value to make use of other attributes.
      #
      if !@set && @default_block
        default_hash = services.execute_attr_default_block(@node, @default_block)
        if !default_hash.hash?
          attr_error("#{describe} default requires a hash not a '#{default_hash.class}'")
        end
        default_hash.each do |k, v|
          insert_key(k, v, *args, **keyval_args)
        end
      end

      # Insert key after defaults to enable defaults to be overwritten if desired
      #
      if !no_keyval
        insert_key(key, val, *args, **keyval_args)
      end

      @set = true
      nil
    end
    
    # If the attribute was never set by the user and it has a default specified in block form ensure that the default value
    # is applied. Call set with no args to achieve this.
    #
    def finalise
      if !@set && @default_block
        set(no_keyval: true)
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
      insert_key(key, val, *f_options, validate: false, **v_options)
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
     
    def process_flags ; end # nothing yet

  private

    def insert_key(key, val, *args, validate: true, call_on_set: true, **keyval_args)
      attr = JabaAttributeElement.new(@attr_def, @node, self)

      if validate
        call_validators do
          @attr_def.call_block_property(:validate_key, key)
        end
      end

      attr.set(val, *args, validate: validate, __jdl_call_loc: @last_call_location, __key: key, call_on_set: false, **keyval_args)

      if call_on_set
        if @in_on_set
          JABA.error("Reentrancy detected in #{describe} on_set")
        end
        @in_on_set = true
        @attr_def.call_block_property(:on_set, key, val, receiver: @node)
        @in_on_set = false
      end

      # Log overwrites. This behaviour could be beefed up and customised with options if necessary
      #
      existing = @hash[key]
      if existing
        if existing.value != val
          services.log("Overwriting '#{key}' hash key [old=#{existing.value}, new=#{val}] in #{describe}")
        end
      end
      @hash[key] = attr
      attr
    end
  end
end
