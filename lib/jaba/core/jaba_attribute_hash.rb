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
    def initialize(attr_def, node)
      super
      @hash = {}
      if attr_def.default_set? && !@default_block
        attr_def.default.each do |k, v|
          set(k, v)
        end
      end
    end
    
    ##
    # For ease of debugging.
    #
    def to_s
      "#{@attr_def} {#{@hash.size} elems}"
    end

    ##
    # Used in error messages.
    #
    def describe
      "'#{@attr_def.defn_id}' hash attribute"
    end

    ##
    # Returns a read only hash of key->attribute values. Expensive because it must map attributes to their values.
    #
    def value(api_call_loc = nil)
      @last_call_location = api_call_loc if api_call_loc
      if !@set
        if @default_block
          default_hash = services.execute_attr_default_block(@node, @default_block)
          at = @attr_def.jaba_attr_type
          return default_hash.transform_values{|e| at.map_value(e)}
        elsif services.in_attr_default_block?
          jaba_error("Cannot read uninitialised #{describe}")
        end
      end
      values = @hash.transform_values {|e| e.value(api_call_loc)}
      if !@attr_def.reference? # read only, enforce by freezing, unless value is a node
        values.freeze
      end
      values
    end
    
    ##
    #
    def set(*args, no_keyval: false, __api_call_loc: nil, **keyval_args, &block)
      @last_call_location = __api_call_loc if __api_call_loc
      
      key = nil
      val = nil

      # 
      if !no_keyval
        if args.empty?
          jaba_error("#{describe} requires a key/value eg \"#{defn_id} :my_key, 'my value'\"")
        end
        key = args.shift

        # If block given, use it to evaluate value
        #
        val = if block_given?
          @node.eval_jdl(&block)
        else
          if args.empty?
            jaba_error("#{describe} requires a key/value eg \"#{defn_id} :my_key, 'my value'\"")
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
          jaba_error("#{describe} default requires a hash not a '#{default_hash.class}'")
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
    
    ##
    # If the attribute was never set by the user and it has a default specified in block form ensure that the default value
    # is applied. Call set with no args to achieve this.
    #
    def finalise
      if !@set && @default_block
        set(no_keyval: true)
      end
    end

    ##
    # Clone other attribute and add into this hash. Other attribute has already been validated and had any reference resolved.
    # just clone raw value and options. Flags will be processed after, eg stripping duplicates.
    #
    def insert_clone(other)
      v_options = other.value_options
      f_options = other.flag_options
      key = v_options[:__key]
      val = Marshal.load(Marshal.dump(other.raw_value))
      insert_key(key, val, *f_options, **v_options)
    end
    
    ##
    #
    def clear
      @hash.clear
    end
    
    ##
    #
    def fetch(key, fail_if_not_found: true)
      if !@hash.key?(key)
        if fail_if_not_found
          jaba_error("'#{key}' key not found in #{describe}")
        else
          return nil
        end
      end
      @hash[key]
    end
    
    ##
    #
    def visit_attr(&block)
      @hash.each_value{|attr| attr.visit_attr(&block)}
    end
     
    ##
    #
    def process_flags
      # nothing yet
    end

  private

    ##
    #
    def insert_key(key, val, *args, **keyval_args)
      attr = JabaAttributeElement.new(@attr_def, @node)
      attr.set(val, *args, __api_call_loc: @last_call_location, __key: key, **keyval_args)

      # Log overwrites. This behaviour could be beefed up and customised with options if necessary
      #
      existing = @hash[key]
      if existing
        services.log("Overwriting '#{key}' hash key [old=#{existing.value}, new=#{val}] in #{describe}")
      end
      @hash[key] = attr
    end

  end

end
