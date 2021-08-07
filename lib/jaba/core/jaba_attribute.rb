# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaAttributeBase

    attr_reader :services
    attr_reader :node
    attr_reader :attr_def
    
    ##
    #
    def initialize(attr_def, node, outer_attr)
      @services = node.services
      @attr_def = attr_def
      @node = node
      @outer_attr = outer_attr
      @last_call_location = nil
      @set = false
      @default_block = @attr_def.default_block
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
    #
    def single?
      @attr_def.single?
    end

    ##
    #
    def array?
      @attr_def.array?
    end

    ##
    #
    def hash?
      @attr_def.hash?
    end

    ##
    # Used in error messages.
    #
    def describe
      @outer_attr.do_describe
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
    # Allows attributes to be treated the same as JabaObject for error reporting.
    #
    def src_loc
      @last_call_location
    end

    ##
    #
    def jaba_warn(msg)
      obj = @last_call_location ? self : @attr_def
      services.jaba_warn(msg, errobj: obj)
    end

    ##
    #
    def attr_error(msg, callstack: nil)
      jdl_bt = services.get_jdl_backtrace(callstack || caller)
      if jdl_bt.empty?
        obj = @last_call_location ? self : @attr_def
        JABA.error(msg, errobj: obj)
      else
        JABA.error(msg, callstack: jdl_bt)
      end
    end
    
    ##
    #
    def call_validators
      begin
        yield
      rescue => e
        attr_error("#{describe} invalid: #{e.message}", callstack: e.backtrace)
      end
    end

    ##
    #
    def value_from_block(__jdl_call_loc, id:, block_args: nil, &block)
      if @attr_def.node_by_value?
        make_node(id: id, block_args: block_args, __jdl_call_loc: __jdl_call_loc, &block)
      else
        return @node.eval_jdl(&block)
      end
    end
    
    ##
    #
    def make_node(id:, block_args: nil, __jdl_call_loc: nil, &block)
      if !@attr_def.node_by_value?
        JABA.error("Only for use with :node attribute type")
      end
      node_type = @attr_def.node_type
      g = services.get_generator(node_type)
      g.push_definition(services.make_definition(@attr_def.defn_id, block, __jdl_call_loc)) do
        return g.make_node(name: id, parent: @node, block_args: block_args)
      end
    end

  end

  ##
  #
  class JabaAttributeElement < JabaAttributeBase

    attr_reader :value_options
    attr_reader :flag_options

    ##
    #
    def initialize(attr_def, node, parent)
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
    def value(jdl_call_loc = nil)
      @last_call_location = jdl_call_loc if jdl_call_loc
      if jdl_call_loc && @value.is_a?(JabaNode)
        @value.attrs_read_only.__internal_set_jdl_call_loc(jdl_call_loc)
      else
        @value
      end
    end
    
    ##
    #
    def set(*args, __jdl_call_loc: nil, validate: true, __resolve_ref: true, **keyval_args, &block)
      @last_call_location = __jdl_call_loc if __jdl_call_loc

      # Check for read only if calling from definitions, or if not calling from definitions but from library code,
      # allow setting read only attrs the first time, in order to initialise them.
      #
      if (__jdl_call_loc || @set) && !@node.allow_set_read_only_attrs?
        if @attr_def.has_flag?(:read_only)
          attr_error("#{describe} is read only")
        end
      end

      new_value = if block_given?
        value_from_block(__jdl_call_loc, id: "#{@attr_def.defn_id}", &block)
      else
        if @attr_def.node_by_value? && !@outer_attr
          attr_error("Node attributes require a block")
        end
        args.shift
      end

      attr_type = @attr_def.jaba_attr_type
      new_value = attr_type.map_value(new_value)

      @flag_options = args

      # Take a deep copy of value_options so they are private to this attribute
      #
      @value_options = keyval_args.empty? ? {} : Marshal.load(Marshal.dump(keyval_args))

      if new_value.is_a?(Enumerable)
        attr_error("#{describe} must be a single value not a '#{new_value.class}'")
      end

      @flag_options.each do |f|
        if !@attr_def.flag_options.include?(f)
          attr_error("Invalid flag option '#{f.inspect_unquoted}' passed to #{describe}. Valid flags are #{@attr_def.flag_options}")
        end
      end

      # Validate that value options flagged as required have been supplied
      #
      @attr_def.each_value_option do |vo|
        if vo.required
          if !@value_options.key?(vo.id)
            if !vo.items.empty?
              attr_error("In #{describe} '#{vo.id}' option requires a value. Valid values are #{vo.items.inspect}")
            else
              attr_error("In #{describe} '#{vo.id}' option requires a value")
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
            attr_error("In #{describe} invalid value '#{v.inspect_unquoted}' passed to '#{k.inspect_unquoted}' option. Valid values: #{vo.items.inspect}")
          end
        end
      end

      if validate && !new_value.nil?
        call_validators do
          attr_type.validate_value(@attr_def, new_value)
          @attr_def.call_hook(:validate, new_value, @flag_options, **@value_options)
        end
      end

      @value = new_value

      if @attr_def.node_by_reference?
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

      @set = true
      nil
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
          attr_error("Option key '#{key}' not found in #{describe}")
        else
          return nil
        end
      end
      @value_options[key]
    end

    ##
    #
    def map_value_option!
      attr_def.each_value_option do |vod|
        if @value_options.key?(vod.id)
          vo = @value_options[vod.id]
          if vo.array?
            vo.map!{|o| yield vod.id, vod.type, o}
          else
            @value_options[vod.id] = yield vod.id, vod.type, vo
          end
        end
      end
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
      super(attr_def, node, self)
      
      if attr_def.default_set? && !@default_block
        set(attr_def.default)
      end
    end

    ##
    #
    def do_describe
      "'#{@node.defn_id}.#{@attr_def.defn_id}' attribute"
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
    def value(jdl_call_loc = nil)
      @last_call_location = jdl_call_loc if jdl_call_loc
      if !@set
        if @default_block
          val = services.execute_attr_default_block(@node, @default_block)
          @attr_def.jaba_attr_type.map_value(val)
        elsif services.in_attr_default_block?
          attr_error("Cannot read uninitialised #{describe} - it might need a default value")
        else
          nil
        end
      elsif jdl_call_loc && @value.is_a?(JabaNode)
        # Pass on jdl call location to the read only attribute accessor to enable value calls to be chained. This happens
        # if a node-by-value attribute is nested, eg root_attr.sub_attr1.sub_attr2.
        #
        @value.attrs_read_only.__internal_set_jdl_call_loc(jdl_call_loc)
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
