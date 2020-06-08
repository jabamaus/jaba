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
    def initialize(services, attr_def, node)
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
    # Returns a read only hash of key->attribute values. Expensive because it must map attributes to their values.
    #
    def value(api_call_loc = nil)
      if !@set
        if @default_block
          return @services.execute_attr_default_block(@node, @default_block)
        elsif @services.in_attr_default_block?
          @services.jaba_error("Cannot read uninitialised '#{defn_id}' attribute")
        end
      end
      values = @hash.transform_values {|e| e.value(api_call_loc)}
      if !@attr_def.reference? # read only, enforce by freezing, unless value is a node
        values.freeze
      end
      values
    end
    
    ##
    # TODO: handle overwriting
    def set(*args, __api_call_loc: nil, **keyvalue_args, &block)
      @last_call_location = __api_call_loc
      
      # TODO: validate only key passed if block given
      if args.size < 2 && !block_given?
        @services.jaba_error('Hash attribute requires a key and a value')
      end
      
      key = args.shift

      # If block given, use it to evaluate value
      #
      val = block_given? ? @node.eval_api_block(&block) : args.shift

      elem = JabaAttributeElement.new(@services, @attr_def, @node)
      elem.set(val, *args, __api_call_loc: __api_call_loc, __key: key, **keyvalue_args)

      @hash[key] = elem
      @set = true
    end
    
    ##
    # If attribute's default value was specified as a block it is executed here, after the node has been created, since
    # default blocks can be implemented in terms of other attributes. Note that the default block is always executed regardless
    # of whether the user added hash elements as the behaviour of hash attributes is to always merge in new values.
    #
    def finalise
      return if !@default_block
      val = @services.execute_attr_default_block(@node, @default_block)
      val.each do |k, v|
        set(k, v)
      end
    end

    ##
    # Clone other attribute and add into this hash. Other attribute has already been validated and had any reference resolved.
    # just clone raw value and options. Flags will be processed after, eg stripping duplicates.
    #
    def insert_clone(other)
      value_options = other.value_options
      f_options = other.flag_options
      key = value_options[:__key]
      val = Marshal.load(Marshal.dump(other.raw_value))

      elem = JabaAttributeElement.new(@services, @attr_def, @node)
      elem.set(val, *f_options, validate: false, __resolve_ref: false, **value_options)
      
      @hash[key] = elem
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
          @services.jaba_error("'#{key}' key not found in #{@attr_def.defn_id}")
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

  end

end
