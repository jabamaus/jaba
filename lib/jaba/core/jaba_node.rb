# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaNode < JabaObject

    attr_reader :jaba_type
    attr_reader :handle
    attr_reader :attrs
    attr_reader :attrs_read_only
    attr_reader :referenced_nodes
    attr_reader :children
    
    ##
    #
    def initialize(services, definition, jaba_type, handle, parent)
      super(services, definition, JabaNodeAPI.new(self))

      @jaba_type = jaba_type # Won't always be the same as the JabaType in definition
      @handle = handle
      @children = []
      @parent = parent
      if parent
        parent.instance_variable_get(:@children) << self
      end
      @referenced_nodes = []
      
      @attrs = AttributeAccessor.new(self)
      @attrs_read_only = AttributeAccessor.new(self, read_only: true)

      @attributes = []
      @attribute_lookup = {}
      
      jaba_type.attribute_defs.each do |attr_def|
        a = case attr_def.variant
            when :single
              JabaAttributeSingle.new(services, attr_def, self)
            when :array
              JabaAttributeArray.new(services, attr_def, self)
            when :hash
              JabaAttributeHash.new(services, attr_def, self)
            end
        @attributes << a
        @attribute_lookup[attr_def.definition_id] = a
      end
    end

    ##
    #
    def to_s
      @handle
    end
    
    ##
    #
    def <=>(other)
      @handle.casecmp(other.handle)
    end
    
    ##
    #
    def get_attr(attr_id, fail_if_not_found: true, search: false)
      a = @attribute_lookup[attr_id]
      if !a
        if search
          @referenced_nodes.each do |ref_node|
            a = ref_node.get_attr(attr_id, fail_if_not_found: false, search: false)
            if a
              if a.attr_def.has_flag?(:expose)
                return a
              else
                return nil
              end
            end
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
    def visit_node(visit_self: false, type_id: nil, &block)
      yield self if (visit_self and (!type_id || type_id == @jaba_type.definition_id))
      @children.each do |c|
        c.visit_node(visit_self: true, &block)
      end
    end

    ##
    #
    def visit_attr(attr_id = nil, top_level: false, type: nil, &block)
      if top_level
        @attributes.each do |a|
          next if type && type != a.attr_def.type_id
          if block.arity == 2
            yield a, a.value
          else
            yield a
          end
        end
      elsif attr_id
        get_attr(attr_id).visit_attr(&block)
      else
        @attributes.each do |a|
          next if type && type != a.attr_def.type_id
          a.visit_attr(&block)
        end
      end
    end

    ##
    #
    def post_create
      @attributes.each do |a|
        if !a.set?
          if a.required?
            jaba_error("'#{a.definition_id}' attribute requires a value. See #{a.attr_def.definition.source_location}", callstack: @definition.source_location)
          end
          a.set_to_default
        end
        a.process_flags(warn: true)
      end
    end
    
    ##
    # If an attribute set operation is being performed, args contains the 'value' and then a list optional symbols
    # which act as options. eg my_attr 'val', :export, :exclude would make args equal to ['val', :opt1, :opt2]. If
    # however the value being passed in is an array it could be eg [['val1', 'val2'], :opt1, :opt2].
    #  
    def handle_attr(id, *args, api_call_line: nil, _read_only_mode: false, **keyvalue_args, &block)
      # First determine if it is a set or a get operation
      #
      is_get = (args.empty? && keyvalue_args.empty? && !block_given?)

      if is_get
        # If its a get operation, look for attribute in this node and all parent nodes
        #
        a = get_attr(id, search: true, fail_if_not_found: false)
        
        if !a
          attr_def = @jaba_type.definition.get_attr_def(id)
          if !attr_def
            jaba_error("'#{id}' attribute not defined")
          elsif attr_def.type_id == :reference
            null_node = @services.get_null_node(attr_def.referenced_type)
            return null_node.attrs_read_only
          end
          return nil
        end
        
        return a.value(api_call_line)
      else
        a = get_attr(id, search: false, fail_if_not_found: false)
        
        if !a
          attr_def = @jaba_type.definition.get_attr_def(id)
          if !attr_def
            jaba_error("'#{id}' attribute not defined")
          elsif attr_def.jaba_type.definition != @jaba_type.definition
            jaba_error("cannot change referenced '#{id}' attribute")
          end
          return nil
        end

        if _read_only_mode
          jaba_error("'#{id}' attribute is read only")
        end
        
        a.set(*args, api_call_line: api_call_line, **keyvalue_args, &block)
        return nil
      end
    end
    
    ##
    #
    def wipe_attrs(ids)
      ids.flatten.each do |id|
        if !id.symbol?
          jaba_error("'#{id}' must be specified as a symbol")
        end
        get_attr(id).clear
      end
    end
    
    ##
    #
    def make_read_only
      @attrs = @attrs_read_only
    end

  end

  ##
  #
  class AttributeAccessor < BasicObject

    ##
    #
    def initialize(node, read_only: false)
      @node = node
      @read_only = read_only
    end
    
    ##
    #
    def to_s
      @node.to_s
    end
    
    ##
    #
    def method_missing(attr_id, *args, **keyvalue_args, &block)
      @node.handle_attr(attr_id, *args, _read_only_mode: @read_only, **keyvalue_args, &block)
    end
   
  end

end
