# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaAttributeBase

    attr_reader :node
    attr_reader :attr_def
    attr_reader :last_call_location
    
    ##
    #
    def initialize(attr_def, node)
      @attr_def = attr_def
      @node = node
      @last_call_location = nil
      @set = false
      @default_block = @attr_def.default_block
    end

    ##
    #
    def services
      @node.services
    end

    ##
    #
    def type_id
      @attr_def.type_id
    end
    
    ##
    #
    def defn_id
      @attr_def.defn_id
    end
    
    ##
    # Used in error messages.
    #
    def describe
      "'#{@attr_def.defn_id}' attribute"
    end

    ##
    #
    def set?
      @set
    end
    
    ##
    #
    def required?
      @attr_def.has_flag?(:required)
    end
    
    ##
    # Returns file and line number but using file basename instead of full path.
    #
    def last_call_loc_basename
      "#{@last_call_location.path.basename}:#{@last_call_location.lineno}"
    end

    ##
    #
    def jaba_warning(msg)
      cs = @last_call_location ? @last_call_location : @attr_def.definition.src_loc_raw
      services.jaba_warning(msg, callstack: cs)
    end

    ##
    #
    def jaba_error(msg)
      cs = @last_call_location ? @last_call_location : @attr_def.definition.src_loc_raw
      services.jaba_error(msg, callstack: cs)
    end
    
  end

  ##
  #
  class JabaAttributeElement < JabaAttributeBase

    attr_reader :value_options
    attr_reader :flag_options

    ##
    #
    def initialize(attr_def, node)
      super
      @value = nil
      @flag_options = nil
      @value_options = nil
    end
    
    ##
    # For ease of debugging.
    #
    def to_s
      "#{@attr_def} value=#{@value}"
    end

    ##
    # Returns the value of the attribute. If value is a reference to a JabaNode and the call to value() came from user
    # definitions then return the node's attributes rather than the node itself.
    #
    def value(api_call_loc = nil)
      @last_call_location = api_call_loc if api_call_loc
      if api_call_loc && @value.is_a?(JabaNode)
        @value.attrs_read_only
      else
        @value
      end
    end
    
    ##
    #
    def set(*args, __api_call_loc: nil, validate: true, __resolve_ref: true, **keyval_args, &block)
      @last_call_location = __api_call_loc if __api_call_loc

      # Check for read only if calling from definitions, or if not calling from definitions but from library code,
      # allow setting read only attrs the first time, in order to initialise them.
      #
      if (__api_call_loc || @set) && !@node.allow_set_read_only_attrs?
        if @attr_def.has_flag?(:read_only)
          jaba_error("#{describe} is read only")
        end
      end

      @set = true

      new_value = block_given? ? @node.eval_jdl(&block) : args.shift
      @flag_options = args

      # Take a deep copy of value_options so they are private to this attribute
      #
      @value_options = keyval_args.empty? ? {} : Marshal.load(Marshal.dump(keyval_args))

      if new_value.is_a?(Enumerable)
        jaba_error("#{describe} must be a single value not a '#{new_value.class}'")
      end

      @flag_options.each do |f|
        if !@attr_def.flag_options.include?(f)
          jaba_error("Invalid flag option '#{f.inspect_unquoted}' passed to #{describe}. Valid flags are #{@attr_def.flag_options}")
        end
      end

      # Validate that value options flagged as required have been supplied
      #
      @attr_def.each_value_option do |vo|
        if vo.required
          if !@value_options.key?(vo.id)
            if !vo.items.empty?
              jaba_error("In #{describe} '#{vo.id}' option requires a value. Valid values are #{vo.items.inspect}")
            else
              jaba_error("In #{describe} '#{vo.id}' option requires a value")
            end
          end
        end
      end

      # Validate that all supplied value options exist and have valid values
      #
      @value_options.each do |k, v|
        vo = @attr_def.get_value_option(k)
        if !vo.items.empty?
          if !vo.items.include?(v)
            jaba_error("In #{describe} invalid value '#{v.inspect_unquoted}' passed to '#{k.inspect_unquoted}' option. Valid values: #{vo.items.inspect}")
          end
        end
      end

      if validate && !new_value.nil?
        begin
          services.set_warn_object(@last_call_location) do
            @attr_def.jaba_attr_type.call_hook(:validate_value, new_value, receiver: @attr_def)
            @attr_def.call_hook(:validate, new_value, @flag_options, **@value_options)
          end
        rescue JDLError => e
          cs = [e.backtrace[0]]
          cs << (@last_call_location ? @last_call_location : @attr_def.definition.src_loc_raw)
          services.jaba_error("#{describe} failed validation: #{e.raw_message}", callstack: cs)
        end
      end

      @value = new_value

      if @attr_def.reference?
        if __resolve_ref
          # Only resolve reference immediately if referencing a different type to this node's type. This is because not all nodes
          # of the same type will have been created by this point whereas nodes of a different type will all have been created
          # due to having been dependency sorted. References to the same type are resolved after all nodes have been created.
          #
          @value = @node.jaba_type.top_level_type.generator.resolve_reference(self, new_value, ignore_if_same_type: true)
        end
      else
        @value.freeze # Prevents value from being changed directly after it has been returned by 'value' method
      end
    end

    ##
    #
    def <=>(other)
      if @value.respond_to?(:casecmp)
        @value.to_s.casecmp(other.value.to_s) # to_s is required because symbols need to be compared to strings
      else
        @value <=> other.value
      end
    end
    
    ##
    #
    def has_flag_option?(o)
      @flag_options&.include?(o)
    end

    ##
    #
    def get_option_value(key, fail_if_not_found: true)
      @attr_def.get_value_option(key)
      if !@value_options.key?(key)
        if fail_if_not_found
          jaba_error("option key '#{key}' not found in #{describe}")
        else
          return nil
        end
      end
      @value_options[key]
    end

    ##
    #
    def visit_attr(&block)
      if block.arity == 2
        yield self, value
      else
        yield self
      end
    end
    
    ##
    # This can only be called after the value has had its final value set as it gives raw access to value.
    #
    def raw_value
      @value
    end

    ##
    # This can only be called after the value has had its final value set as it gives raw access to value.
    #
    def map_value!
      @value = yield(@value)
    end
    
    ##
    #
    def process_flags
      # Nothing yet
    end

  end

  ##
  #
  class JabaAttributeSingle < JabaAttributeElement

    ##
    #
    def initialize(attr_def, node)
      super
      
      if attr_def.default_set? && !@default_block
        set(attr_def.default)
      end
    end

    ##
    # If attribute's default value was specified as a block it is executed here, after the node has been created, since
    # default blocks can be implemented in terms of other attributes. If the user has already supplied a value then the
    # default block will not be executed.
    #
    def finalise
      return if !@default_block || @set
      val = services.execute_attr_default_block(@node, @default_block)
      set(val)
    end

    ##
    # Returns the value of the attribute. If value is a reference to a JabaNode and the call to value() came from user
    # definitions then return the node's attributes rather than the node itself.
    #
    def value(api_call_loc = nil)
      @last_call_location = api_call_loc if api_call_loc
      if !@set
        if @default_block
          services.execute_attr_default_block(@node, @default_block)
        elsif services.in_attr_default_block?
          jaba_error("Cannot read uninitialised #{describe}")
        else
          nil
        end
      elsif api_call_loc && @value.is_a?(JabaNode)
        @value.attrs_read_only
      else
        @value
      end
    end

    ##
    # TODO: re-examine
    def clear
      if attr_def.default_set? && !@default_block
        @value = attr_def.default
      else
        @value = nil
      end
    end

  end

end
