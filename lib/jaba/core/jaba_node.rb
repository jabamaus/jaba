# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
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
    def method_missing(attr_id, *args, **keyvalue_args)
      @node.handle_attr(attr_id, nil, *args, **keyvalue_args)
    end
    
  end
  
  ##
  #
  class JabaNode < DefinitionObject

    attr_reader :jaba_type
    attr_reader :id
    attr_reader :handle
    attr_reader :attrs
    attr_reader :generate_hooks
    attr_reader :referenced_nodes
    attr_reader :children
    attr_reader :source_file
    attr_reader :source_dir
    
    ##
    #
    def initialize(services, info, handle, attrs_mask, parent)
      super(services)

      @jaba_type = info.type
      @id = info.id
      @handle = handle
      @children = []
      @parent = parent
      if parent
        parent.instance_variable_get(:@children) << self
      end
      @referenced_nodes = []
      
      @api_call_line = info.api_call_line
      @source_file = @api_call_line[/^(.+):\d/, 1]
      @source_dir = File.dirname(@source_file)
      
      @attrs = NodeAttributeInterface.new(self)
      @attributes = []
      @attribute_lookup = {}
      @attr_def_mask = attrs_mask
      @generate_hooks = []
      
      @jaba_type.iterate_attrs(attrs_mask) do |attr_def|
        a = case attr_def.variant
            when :single
              Attribute.new(services, attr_def, nil, self)
            when :array
              AttributeArray.new(services, attr_def, self)
            end
        @attribute_lookup[attr_def.id] = a
        @attributes << a
      end

      @services.log_debug("Making node [type=#{@jaba_type} id=#{@id} handle=#{handle}, parent=#{parent}")
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
    #
    def method_missing(attr_id, *args, **keyvalue_args)
      handle_attr(attr_id, ::Kernel.caller(1, 1)[0], *args, **keyvalue_args)
    end
    
    ##
    # If an attribute set operation is being performed, args contains the 'value' and then a list optional symbols
    # which act as options. eg my_attr 'val', :export, :exclude would make args equal to ['val', :opt1, :opt2]. If
    # however the value being passed in is an array it could be eg [['val1', 'val2'], :opt1, :opt2].
    #  
    def handle_attr(id, api_call_line, *args, **keyvalue_args)
      # First determine if it is a set or a get operation
      #
      is_get = (args.empty? && keyvalue_args.empty?)

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
        a.set(value, api_call_line, *args, **keyvalue_args)
        return nil
      end
    end
    
    ##
    # DEFINITION API
    #
    def generate(&block)
      define_hook(:generate, allow_multiple: true, &block)
    end
    
    ##
    # DEFINITION API
    #
    # Clears any previously set values. Sets single attribute values to nil and clears array attributes.
    #
    def wipe(*attr_ids)
      wipe_attrs(attr_ids)
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
