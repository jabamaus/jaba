# frozen_string_literal: true

module JABA

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
      @args = nil
      @key_value_args = nil
      
      # If its not an element of an attribute array, initialize with default value if it has a concrete one
      #
      if !parent_array && !@default.nil? && !@default_is_proc
        validate_value(@default, nil)
        @value = @default # TODO: should this take a copy?
        @set = true
      end
    end
    
    ##
    #
    def get
      if !set? && @default_is_proc
        @node.api_eval(&@default)
      else
        @value
      end
    end
    
    ##
    #
    def set(value, api_call_line = nil, *args, **key_value_args)
      @services.log_debug "setting '#{@node.id}##{id}' [value=#{value} args=#{args} key_value_args=#{key_value_args}]"
      @api_call_line = api_call_line
      @args = args
      @key_value_args = key_value_args
      
      validate_value(value, api_call_line)

      # TODO: fix
      @value = if @attr_def.type == :keyvalue
                 { value => args[0] }
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
      yield @value
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
        @services.jaba_error("'#{@attr_def.id}' attribute is not an array so cannot accept one")
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
    def get
      if !set? && @default_is_proc
        @node.api_eval(&@default)
      else
        @elems.map(&:get)
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
      @elems.each_value(&block)
    end
    
    ##
    #
    def map!(&block)
      @elems.map!(&block)
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
          @elems.sort!
        rescue StandardError
          @services.jaba_error("Failed to sort #{id}. Might be missing <=> operator", callstack: api_call_line)
        end
      end
    end
    
  end

  ##
  #
  class JabaNode < JabaAPIObject

    attr_reader :jaba_type
    attr_reader :handle
    attr_reader :attributes
    attr_reader :generate_hooks
    
    ##
    #
    def initialize(services, jaba_type, handle, attrs_mask, parent, source_location)
      super(services, services.jaba_node_api)
      @jaba_type = jaba_type
      @handle = handle
      @parent = parent
      @source_location = source_location
      
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
    # TODO: This needs testing
    def get_attr(attr_id, fail_if_not_found: true, search_parents: false)
      a = @attribute_lookup[attr_id]
      if !a
        if search_parents && @parent
          return @parent.get_attr(attr_id, fail_if_not_found: false, search_parents: true)
        end
        if fail_if_not_found
          @services.jaba_error("'#{attr_id}' attribute not found")
        end
      end
      a
    end
    
    ##
    #
    def post_create
      @attributes.each do |a|
        if a.required? && !a.set?
          @services.jaba_error("'#{a.id}' attribute requires a value", 
                               callstack: [@source_location.join(':'), a.attr_def.source_location.join(':')]) # TODO
        end
        a.process_flags(warn: true)
      end
    end
    
    ##
    #
    def save_file(filename, content, eol)
      @services.save_file(filename, content, eol)
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
        a = get_attr(id, search_parents: true, fail_if_not_found: false)
        
        if !a
          # TODO: check if property is defined at all
          return nil
        end
        
        return a.get
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
    def method_missing(attr_id, *args, **key_value_args)
      handle_attr(attr_id, nil, *args, **key_value_args)
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
