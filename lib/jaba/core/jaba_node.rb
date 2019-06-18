# frozen_string_literal: true

module JABA

  using JABACoreExt
  
  ##
  #
  KeyValue = Struct.new(:key, :value) do
    def <=>(other)
      if key.respond_to?(:casecmp)
        key.to_s.casecmp(other.key.to_s)
      else
        key <=> other.key
      end
    end
  end
  
  ##
  #
  class AttributeBase

    attr_reader :attr_def
    attr_reader :api_call_line
    
    ##
    #
    def initialize(services, attr_def, node)
      @services = services
      @attr_def = attr_def
      @node = node
      @api_call_line = nil
      @set = false
      @default = @attr_def.default
      @default_is_proc = @default.is_a?(Proc)
    end
    
    ##
    #
    def type
      @attr_def.type
    end
    
    ##
    #
    def id
      @attr_def.id
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
    
  end

  ##
  #
  class Attribute < AttributeBase

    ##
    #
    def initialize(services, attr_def, parent_array, node)
      super(services, attr_def, node)
      @value = nil
      @options = nil
      @key_value_options = nil
      
      # If its not an element of an attribute array, initialize with default value if it has a concrete one
      #
      if !parent_array && !@default.nil? && !@default_is_proc
        validate_value(@default, attr_def.api_call_line)
        @value = @default
        @set = true
      end
    end
    
    ##
    #
    def get(api_call_line = nil)
      if !set? && @default_is_proc
        @node.api_eval(&@default)
      elsif api_call_line && @value.is_a?(JabaNode)
        @value.id
      else
        @value
      end
    end
    
    ##
    #
    def set(value, api_call_line = nil, *args, **key_value_args)
      @services.log_debug "setting '#{@node.id}##{id}' [value=#{value} args=#{args} key_value_args=#{key_value_args}]"
      @api_call_line = api_call_line
      @options = args
      @key_value_options = key_value_args
      
      validate_value(value, api_call_line)

      # TODO: fix
      @value = if @attr_def.type == :keyvalue
                 KeyValue.new(value, args[0])
                 # TODO: remove args[0] from options
               elsif @attr_def.type == :reference && @attr_def.get_var(:referenced_type) != @node.jaba_type.type
                 ref_node = @services.node_from_handle(value)
                 @node.referenced_nodes << ref_node
                 ref_node
               else
                 value
               end
      @set = true
    end
    
    ##
    #
    def clear
      @value = nil
      d = @attr_def.default
      if !d.nil? && !@default_is_proc
        @value = d
      end
    end
    
    ##
    #
    def <=>(other)
      if @value.respond_to?(:casecmp)
        @value.to_s.casecmp(other.get.to_s)
      else
        @value <=> other.get
      end
    end
    
    ##
    #
    def each_value
      yield @value, @options, @key_value_options
    end
    
    ##
    #
    def map!
      @value = yield(@value)
    end
    
    ##
    #
    def process_flags(warn: true)
      # Nothing
    end
    
    private
    
    ##
    #
    def validate_value(value, api_call_line)
      if value.is_a?(Array)
        @services.jaba_error("'#{@attr_def.id}' attribute is not an array so cannot accept one", callstack: api_call_line)
      end
      if api_call_line
        hook = @attr_def.type_obj.validate_value_hook
        if hook
          begin
            @attr_def.api_eval(value, &hook)
          rescue JabaError => e
            @services.jaba_error("'#{@attr_def.id}' attribute failed validation: #{e.raw_message}", callstack: e.backtrace)
          end
        end
      end
    end
    
  end

  ##
  #
  class AttributeArray < AttributeBase
    
    ##
    #
    def initialize(services, attr_def, node)
      super
      @elems = []
      @excludes = []
      if @default.is_a?(Array)
        set(@default)
      end
    end
    
    ##
    #
    def get(api_call_line = nil)
      if !set? && @default_is_proc
        @node.api_eval(&@default)
      else
        @elems.map {|e| e.get(api_call_line)}
      end
    end
    
    ##
    #
    def set(values, api_call_line = nil, *args, prefix: nil, postfix: nil, exclude: nil, **key_value_args)
      @api_call_line = api_call_line
      
      Array(values).each do |v|
        elem = Attribute.new(@services, @attr_def, self, @node)
        v = apply_pre_post_fix(prefix, postfix, v)
        elem.set(v, api_call_line, *args, **key_value_args)
        @elems << elem
        @set = true
      end
      
      if exclude
        Array(exclude).each do |e|
          @excludes << apply_pre_post_fix(prefix, postfix, e)
        end
      end
    end
    
    ##
    #
    def apply_pre_post_fix(pre, post, val)
      if pre || post
        if !val.is_a?(String)
          @services.jaba_error('prefix/postfix option can only be used with arrays of strings', callstack: api_call_line)
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
    #
    def each_value(&block)
      @elems.each {|e| e.each_value(&block)}
    end
    
    ##
    #
    def map!(&block)
      @elems.each {|e| e.map!(&block)}
    end
    
    ##
    #
    def process_flags(warn: true)
      if @excludes
        @elems.delete_if do |e|
          @excludes.any? do |ex|
            val = e.get
            if ex.is_a?(Proc)
              ex.call(val)
            elsif ex.is_a?(Regexp)
              if !val.is_a?(String)
                @services.jaba_error('exclude regex can only operate on strings', callstack: e.api_call_line)
              end
              val.match(ex)
            else
              ex == val
            end
          end
        end
      end
      if !@attr_def.has_flag?(:allow_dupes)
        if @elems.uniq!(&:get) && warn
          @services.jaba_warning("'#{id}' array attribute contains duplicates", callstack: api_call_line)
        end
      end
      if !@attr_def.has_flag?(:unordered)
        begin
          @elems.stable_sort!
        rescue StandardError
          @services.jaba_error("Failed to sort #{id}. Might be missing <=> operator", callstack: api_call_line)
        end
      end
    end
    
  end

  ##
  #
  class NodeAttributeInterface < BasicObject
    
    ##
    #
    def initialize(node)
      @node = node
    end
    
    ##
    #
    def method_missing(attr_id, *args, **key_value_args)
      @node.handle_attr(attr_id, nil, *args, **key_value_args)
    end
    
  end
  
  ##
  #
  class JabaNode < JabaAPIObject

    attr_reader :jaba_type
    attr_reader :id
    attr_reader :handle
    attr_reader :attrs
    attr_reader :generate_hooks
    attr_reader :referenced_nodes
    
    ##
    #
    def initialize(services, jaba_type, id, handle, attrs_mask, parent, api_call_line)
      super(services, JabaNodeAPI.new)
      @services.log_debug("Making node [type=#{jaba_type.type} id=#{id} handle=#{handle}, " \
                          "parent=#{parent}, api_call_line=#{api_call_line}]")

      @jaba_type = jaba_type
      @id = id
      @handle = handle
      @parent = parent
      @referenced_nodes = []
      @api_call_line = api_call_line
      
      @attrs = NodeAttributeInterface.new(self)
      @attributes = []
      @attribute_lookup = {}
      @attr_def_mask = attrs_mask
      @generate_hooks = []
      
      @jaba_type.iterate_attrs(attrs_mask) do |attr_def|
        a = attr_def.array? ? AttributeArray.new(services, attr_def, self) : Attribute.new(services, attr_def, nil, self)
        @attribute_lookup[attr_def.id] = a
        @attributes << a
      end
    end
    
    ##
    #
    def <=>(other)
      @id.casecmp(other.id)
    end
    
    ##
    #
    def get_attr(attr_id, fail_if_not_found: true, search: false)
      a = @attribute_lookup[attr_id]
      if !a
        if search
          @referenced_nodes.each do |ref_node|
            a = ref_node.get_attr(attr_id, fail_if_not_found: false, search: false)
            return a if a
          end
          if @parent
            return @parent.get_attr(attr_id, fail_if_not_found: false, search: true)
          end
        end
        if fail_if_not_found
          @services.jaba_error("'#{attr_id}' attribute not found")
        end
      end
      a
    end
    
    ##
    #
    def each_attr(&block)
      @attributes.each(&block)
    end
    
    ##
    #
    def post_create
      @attributes.each do |a|
        if a.required? && !a.set?
          @services.jaba_error("'#{a.id}' attribute requires a value", 
                               callstack: [@api_call_line, a.attr_def.api_call_line])
        end
        a.process_flags(warn: true)
      end
    end
    
    ##
    # If an attribute set operation is being performed, args contains the 'value' and then a list optional symbols
    # which act as options. eg my_attr 'val', :export, :exclude would make args equal to ['val', :opt1, :opt2]. If
    # however the value being passed in is an array it could be eg [['val1', 'val2'], :opt1, :opt2].
    #  
    def handle_attr(id, api_call_line, *args, **key_value_args)
      # First determine if it is a set or a get operation
      #
      is_get = (args.empty? && key_value_args.empty?)

      if is_get
        # If its a get operation, look for attribute in this node and all parent nodes
        #
        a = get_attr(id, search: true, fail_if_not_found: false)
        
        if !a
          # TODO: check if property is defined at all
          return nil
        end
        
        return a.get(api_call_line)
      else
        if @attr_def_mask&.none? {|m| m == id}
          return nil
        end

        a = get_attr(id)
        
        # Get the value by popping the first element from the front of the list. This could yield a single value or an
        # array, depending on what the user passed in (see comment at top of this method.
        #
        value = args.shift
        a.set(value, api_call_line, *args, **key_value_args)
        return nil
      end
    end
    
    ##
    #
    def wipe_attrs(ids)
      ids.each do |id|
        if !id.is_a?(Symbol)
          @services.jaba_error("'#{id}' must be specified as a symbol")
        end
        get_attr(id).clear
      end
    end
    
  end

end
