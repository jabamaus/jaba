# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaNode < JDL_Object

    attr_reader :jaba_type
    attr_reader :handle
    attr_reader :attrs
    attr_reader :attrs_read_only
    attr_reader :parent
    attr_reader :children
    attr_reader :depth
    
    ##
    #
    def initialize(services, defn_id, src_loc, jaba_type, handle, parent, depth)
      super(services, defn_id, src_loc, JDL_Node.new(self))

      @jaba_type = jaba_type # Won't always be the same as the JabaType in definition
      @handle = handle
      @children = []
      @parent = parent
      if parent
        parent.instance_variable_get(:@children) << self
      end
      @depth = depth
      @referenced_nodes = []
      
      @attrs = AttributeAccessor.new(self)
      @attrs_read_only = AttributeAccessor.new(self, read_only: true)
      @read_only = false
      @allow_set_read_only_attrs = false

      @attributes = []
      @attribute_lookup = {}
      
      i = 0
      adefs = jaba_type.attribute_defs
      s = adefs.size
      while i < s
        attr_def = adefs[i]
        i += 1
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
      end

      # Define a generate hook on root node only
      #
      if !parent
        define_hook(:generate)
      end
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
    def get_attr(attr_id, fail_if_not_found: true, search: false)
      a = @attribute_lookup[attr_id]
      if !a
        if search
          i = 0
          s = @referenced_nodes.size
          while i < s
            ref_node = @referenced_nodes[i]
            i += 1
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
          JABA.error("'#{@defn_id}.#{attr_id}' attribute not found")
        end
      end
      a
    end
    
    ##
    #
    def visit_node(visit_self: false, type_id: nil, &block)
      jaba_type_id = @jaba_type.handle
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
        i = 0
        s = @attributes.size
        while i < s
          a = @attributes[i]
          i += 1
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
    # Removes attribute and returns it.
    #
    def remove_attr(attr_id)
      if @attribute_lookup.delete(attr_id).nil?
        JABA.error("Could not remove '#{attr_id}' attribute from #{describe}")
      end
      index = @attributes.index{|a| a.defn_id == attr_id}
      if index.nil?
        JABA.error("Could not remove '#{attr_id}' attribute from #{describe}")
      end
      @attributes.delete_at(index)
    end

    ##
    # TODO: improve
    def pull_up(*attr_ids)
      attr_ids.each do |attr_id|
        attr = nil
        # TODO: check commonality
        @children.each do |child|
          attr = child.remove_attr(attr_id)
        end
        @attributes << attr
        @attribute_lookup[attr_id] = attr
      end
    end

    ##
    # 
    def post_create
      i = 0
      s = @attributes.size
      while i < s
        a = @attributes[i]
        i += 1
        if !a.set? && a.required?
          JABA.error("#{a.describe} requires a value. See #{a.attr_def.src_loc.describe}", errobj: self)
        end
      
        a.finalise

        # Note that it is still possible for attributes to not be marked as 'set' by this point, ie if the user never
        # set it and it didn't have a default. But by this point the set flag has served it purpose.
      end
    end
    
    ##
    # If an attribute set operation is being performed, args contains the 'value' and then a list optional symbols
    # which act as options. eg my_attr 'val', :export, :exclude would make args equal to ['val', :opt1, :opt2]. If
    # however the value being passed in is an array it could be eg [['val1', 'val2'], :opt1, :opt2].
    #  
    def handle_attr(id, *args, __api_call_loc: nil, __read_only: false, **keyval_args, &block)
      # First determine if it is a set or a get operation
      #
      is_get = (args.empty? && keyval_args.empty? && !block_given?)

      if is_get
        # If its a get operation, look for attribute in this node and all parent nodes
        #
        a = get_attr(id, search: true, fail_if_not_found: false)
        
        if !a
          attr_def = @jaba_type.top_level_type.get_attr_def(id)
          if !attr_def
            JABA.error("'#{id}' attribute not defined in #{describe}")
          elsif attr_def.node_by_reference?
            null_node = services.get_null_node(attr_def.node_type)
            return null_node.attrs_read_only
          end
          return nil
        end
        
        return a.value(__api_call_loc)
      else
        a = get_attr(id, search: false, fail_if_not_found: false)
        
        if !a
          attr_def = @jaba_type.top_level_type.get_attr_def(id)
          if !attr_def
            JABA.error("'#{id}' attribute not defined")
          elsif attr_def.jaba_type.defn_id != @jaba_type.defn_id
            JABA.error("Cannot change referenced '#{id}' attribute")
          end
          return nil
        end

        if (__read_only || @read_only) && !@allow_set_read_only_attrs
          JABA.error("#{a.describe} is read only")
        end
        
        a.set(*args, __api_call_loc: __api_call_loc, **keyval_args, &block)
        return nil
      end
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
    # Temporarily allow setting read only attrs. Used in generator make_nodes methods when initialising read only attributes
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

  end

  ##
  #
  class AttributeAccessor < BasicObject

    ##
    #
    def initialize(node, read_only: false)
      @node = node
      @read_only = read_only
      @api_call_loc = nil
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
    
    # Store api call location (only done in read only version of this accessor) so it can be passed on to enable value calls to be chained. This happens
    # if a node-by-value attribute is nested, eg root_attr.sub_attr1.sub_attr2.
    #
    def __internal_set_api_call_loc(api_call_loc)
      @api_call_loc = api_call_loc
      self
    end

    ##
    #
    def method_missing(attr_id, *args, **keyval_args, &block)
      @node.handle_attr(attr_id, *args, __api_call_loc: @api_call_loc, __read_only: @read_only, **keyval_args, &block)
    end
   
  end

end
