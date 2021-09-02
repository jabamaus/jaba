# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaNode < JabaObject

    attr_reader :node_manager
    attr_reader :jaba_type
    attr_reader :handle
    attr_reader :attrs
    attr_reader :attrs_read_only
    attr_reader :parent
    attr_reader :children
    attr_reader :depth
    
    ##
    #
    def initialize(node_manager, defn_id, src_loc, jaba_type, handle, parent, depth, lazy)
      super(node_manager.services, defn_id, src_loc, JDL_Node.new(self))

      @node_manager = node_manager
      @jaba_type = jaba_type
      @handle = handle
      @children = []
      @depth = depth
      @lazy = lazy
      @referenced_nodes = []
      
      @attrs = AttributeAccessor.new(self)
      @attrs_read_only = AttributeAccessor.new(self, read_only: true)
      @read_only = false
      @allow_set_read_only_attrs = false

      @attributes = []
      @attribute_lookup = {}
      
      set_parent(parent)

      if !lazy
        @jaba_type.attribute_defs.each do |attr_def|
          create_attr(attr_def)
        end
      end

      define_block_property(:generate)
    end

    ##
    #
    def to_s
      @handle
    end
    
    ##
    #
    def inspect
      @defn_id.inspect
    end

    ##
    # Used in error messages.
    #
    def describe
      "'#{@handle}' node"
    end

    ##
    #
    def <=>(other)
      @handle.casecmp(other.handle)
    end

    ##
    #
    def add_node_reference(node)
      # TODO: handle duplicates
      @referenced_nodes << node
    end
   
    ##
    #
    def visit_node(visit_self: false, type_id: nil, &block)
      jaba_type_id = @jaba_type.defn_id
      if (visit_self && (!type_id || type_id == jaba_type_id))
        yield self
      end
      @children.each do |c|
        c.visit_node(visit_self: true, type_id: type_id, &block)
      end
    end

    ##
    # Prefer over visit_attr when only basic unfiltered iteration is required, over top level attributes only.
    #
    def each_attr(&block)
      @attributes.each(&block)
    end

    ##
    # Multi-purpose visit method. Works in multiple modes. 
    #
    def visit_attr(attr_id = nil, top_level: false, type: nil, skip_variant: nil, skip_attr: nil, &block)
      if attr_id
        get_attr(attr_id).visit_attr(&block)
      else
        @attributes.each do |a|
          next if skip_attr && a.defn_id == skip_attr
          next if type && !Array(type).include?(a.attr_def.type_id)
          next if skip_variant && skip_variant == a.attr_def.variant
          if top_level
            if block.arity == 2
              yield a, a.value
            else
              yield a
            end
          else
            a.visit_attr(&block)
          end
        end
      end
    end

    ##
    # 
    def post_create
      @attributes.each do |a|
        if !a.set? && a.required?
          JABA.error("#{a.describe} requires a value. See #{a.attr_def.src_loc.describe}", errobj: self)
        end
      
        a.finalise

        # Note that it is still possible for attributes to not be marked as 'set' by this point, ie if the user never
        # set it and it didn't have a default. But by this point the set flag has served it purpose.
      end
    end
    
    ##
    #
    def get_attr(id, fail_if_not_found: true)
      a = @attribute_lookup[id]
      if !a && fail_if_not_found
        attr_not_found_error(id)
      end
      a
    end

    ##
    #
    def search_attr(id, fail_if_not_found: true)
      a = get_attr(id, fail_if_not_found: false)
      if !a
        @referenced_nodes.each do |rn|
          a = rn.get_attr(id, fail_if_not_found: false)
          if a && a.attr_def.has_flag?(:expose)
            return a
          else
            a = nil
          end
        end
        if @parent
          a = @parent.search_attr(id, fail_if_not_found: false)
        end
      end
      if !a && fail_if_not_found
        attr_not_found_error(id)
      end
      a
    end

    ##
    # If an attribute set operation is being performed, args contains the 'value' and then a list optional symbols
    # which act as options. eg my_attr 'val', :export, :exclude would make args equal to ['val', :opt1, :opt2]. If
    # however the value being passed in is an array it could be eg [['val1', 'val2'], :opt1, :opt2].
    #  
    def handle_attr(id, *args, __jdl_call_loc: nil, __read_only: false, **keyval_args, &block)
      # First determine if it is a set or a get operation
      #
      is_get = (args.empty? && keyval_args.empty? && !block_given?)

      # If its a get operation, search for attribute in this node, all referenced nodes and all parent nodes
      #
      if is_get
        a = search_attr(id)
        return a.value(__jdl_call_loc)
      else
        a = get_attr(id, fail_if_not_found: false)
        
        if !a && @lazy
          attr_def = @jaba_type.get_attr_def(id)
          if attr_def
            a = create_attr(attr_def)
          end
        end
          
        if !a
          attr_def = @jaba_type.get_attr_def(id)
          if attr_def && attr_def.jaba_type.defn_id != @jaba_type.defn_id
            JABA.error("Cannot change referenced '#{id}' attribute")
          end
          attr_not_found_error(id)
        end

        if (__read_only || @read_only) && !@allow_set_read_only_attrs
          JABA.error("#{a.describe} is read only")
        end
        
        a.set(*args, __jdl_call_loc: __jdl_call_loc, **keyval_args, &block)
        return nil
      end
    end

    ##
    # TODO: 'did you mean' style error msg
    #
    def attr_not_found_error(id)
      JABA.error("'#{id}' attribute not found. Available: #{@jaba_type.callable_attr_defs.map{|ad| ad.defn_id}.inspect}")
    end

    ##
    #
    def wipe_attrs(ids)
      ids.flatten.each do |id|
        if !id.symbol?
          JABA.error("'#{id}' must be specified as a symbol")
        end
        get_attr(id).clear
      end
    end
 
    ##
    #
    def allow_set_read_only_attrs?
      @allow_set_read_only_attrs
    end

    ##
    # Temporarily allow setting read only attrs. Used in NodeManager#process_definition methods when initialising read only attributes
    #
    def allow_set_read_only_attrs
      @allow_set_read_only_attrs = true
      yield
      @allow_set_read_only_attrs = false
    end
    
    ##
    #
    def make_read_only
      old_attrs = @attrs
      @attrs = @attrs_read_only
      @read_only = true

      if block_given?
        yield
        @attrs = old_attrs
        @read_only = false
      end
    end

    ##
    #
    def set_parent(parent)
      if @parent
        @parent.children.delete(self)
      end
      @parent = parent
      if @parent
        @parent.children << self
      end
    end

  private

    ##
    #
    def create_attr(attr_def)
      a = case attr_def.variant
      when :single
        JabaAttributeSingle.new(attr_def, self)
      when :array
        JabaAttributeArray.new(attr_def, self)
      when :hash
        JabaAttributeHash.new(attr_def, self)
      end
      @attributes << a
      @attribute_lookup[attr_def.defn_id] = a
      a
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
      @jdl_call_loc = nil
    end
    
    ##
    #
    def to_s
      @node.to_s
    end
    
    ##
    #
    def id
      @node.defn_id
    end
    
    # Store jdl call location (only done in read only version of this accessor) so it can be passed on to enable value calls to be chained. This happens
    # if a node-by-value attribute is nested, eg root_attr.sub_attr1.sub_attr2.
    #
    def __internal_set_jdl_call_loc(jdl_call_loc)
      @jdl_call_loc = jdl_call_loc
      self
    end

    ##
    #
    def method_missing(attr_id, *args, **keyval_args, &block)
      @node.handle_attr(attr_id, *args, __jdl_call_loc: @jdl_call_loc, __read_only: @read_only, **keyval_args, &block)
    end
   
  end

end
