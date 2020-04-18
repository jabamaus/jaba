# frozen_string_literal: true

##
#
module JABA

  ##
  #
  class JabaNode < JabaObject

    attr_reader :jaba_type
    attr_reader :definition_id # As specified by user in definition files.
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
    def initialize(services, jaba_type, definition_id, id, api_call_line, handle, parent)
      super(services, JabaNodeAPI.new(self))

      @jaba_type = jaba_type
      @definition_id = definition_id
      @id = id
      @api_call_line = api_call_line
      @handle = handle
      @children = []
      @parent = parent
      if parent
        parent.instance_variable_get(:@children) << self
      end
      @referenced_nodes = []
      
      @source_file = @api_call_line[/^(.+):\d/, 1]
      @source_dir = File.dirname(@source_file)
      
      @attrs = AttributeAccessor.new(self)

      @attributes = []
      @attribute_lookup = {}
      @generate_hooks = []
      
      @jaba_type.attribute_defs.each do |attr_def|
        a = case attr_def.variant
            when :single
              JabaAttribute.new(services, attr_def, nil, self)
            when :array
              JabaAttributeArray.new(services, attr_def, self)
            end
        @attributes << a
        @attribute_lookup[attr_def.id] = a
      end

      @services.log_debug("Making node [type=#{@jaba_type} id=#{@id} handle=#{handle}, parent=#{parent}")
    end

    ##
    # For ease of debugging.
    #
    def to_s
      @id.to_s
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
          jaba_error("'#{attr_id}' attribute not found")
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
          jaba_error("'#{a.id}' attribute requires a value", 
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
          # TODO: this needs to consider all types used by a generator
          return nil
        end
        
        return a.get(api_call_line)
      else
        a = get_attr(id, fail_if_not_found: false)
        
        if !a
          # TODO: check if property is defined at all
          # TODO: this needs to consider all types used by a generator
          return nil
        end

        # Get the value by popping the first element from the front of the list. This could yield a single value or an
        # array, depending on what the user passed in (see comment at top of this method.
        #
        value = args.shift
        a.set(value, api_call_line, *args, **keyvalue_args)
        return nil
      end
    end
    
    ##
    #
    def wipe_attrs(ids)
      ids.each do |id|
        if !id.is_a?(Symbol)
          jaba_error("'#{id}' must be specified as a symbol")
        end
        get_attr(id).clear
      end
    end
    
  end

  ##
  #
  class AttributeAccessor < BasicObject

    ##
    #
    def initialize(node)
      @node = node
    end
    
    ##
    #
    def to_s
      @node.to_s
    end
    
    ##
    #
    def method_missing(attr_id, *args, **keyvalue_args)
      @node.handle_attr(attr_id, nil, *args, **keyvalue_args)
    end
   
  end

end
