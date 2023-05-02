module JABA
  # Attriute lookup hash converts keys to symbols so can lookup with strings or symbols
  class AttributeLookupHash < Hash
    def [](key) = super(key.to_sym)
    def []=(key, value); super(key.to_sym, value); end
  end

  class Node
    def initialize(node_def, id, src_loc, parent)
      JABA.error("node_def must not be nil") if node_def.nil?
      @node_def = node_def
      @api_obj = @node_def.api_class.new(self)
      @id = id
      @src_loc = src_loc
      @attributes = []
      @attribute_lookup = AttributeLookupHash.new
      @children = []
      @read_only = false
      @parent = parent
      if parent
        parent.children << self
      end
    end

    def add_attrs(attr_defs)
      attr_defs.each do |d|
        add_attr(d)
      end
    end

    def api_obj = @api_obj
    def eval_jdl(...) = api_obj.instance_exec(...)

    # Compound attrs don't have ids
    def compound_attr? = @id.nil?
    
    def post_create
      @attributes.each do |a|
        if !a.set? && a.required?
          JABA.error("#{a.describe} requires a value", errobj: self)
        end

        a.finalise

        # Note that it is still possible for attributes to not be marked as 'set' by this point, ie if the user never
        # set it and it didn't have a default. But by this point the set flag has served it purpose.
      end
    end

    def id = @id
    def src_loc = @src_loc
    def parent = @parent
    def children = @children
    def attributes = @attributes
    def [](name) = get_attr(name).value    
    
    def visit(&block)
      yield self
      @children.each do |c|
        c.visit(&block)
      end
    end

    def visit_parents(skip_self, &block)
      yield self if !skip_self
      p = @parent
      while p
        yield p
        p = p.parent
      end
    end

    def get_attr(name, fail_if_not_found: true)
      a = @attribute_lookup[name]
      if !a && fail_if_not_found
        attr_not_found_error(name)
      end
      a
    end

    def search_attr(name, skip_self: false, fail_if_not_found: true)
      visit_parents(skip_self) do |node|
        a = node.get_attr(name, fail_if_not_found: false)
        return a if a
      end
      if fail_if_not_found
        attr_not_found_error(name)
      end
      nil
    end

    def handle_attr(name, *args, **kwargs, &block)
      is_get = (args.empty? && kwargs.empty? && !block_given?)
      if is_get
        a = search_attr(name)
        return a.value
      else
        a = get_attr(name, fail_if_not_found: false)
        if a
          if @read_only
            JABA.error("#{a.describe} is read only in this scope", line: $last_call_location)
          end
          a.set(*args, **kwargs, &block)
        else
          # if attr not found on this node search for it in parents. If found it is therefore
          # readonly. Issue a suitable error.
          a = search_attr(name, skip_self: true, fail_if_not_found: false)
          if a
            # Compound attributes are allowed to set 'sibling' attributes which are in its parent node
            if compound_attr? && a.node == @parent
              a.set(*args, **kwargs, &block)
            else
              JABA.error("#{a.describe} is read only in this scope", line: $last_call_location)
            end
          else
            attr_not_found_error(name)
          end
        end
        return nil
      end
    end

    def visit_callable_attrs(rdonly: false, &block)
      @attributes.each do |a|
        if rdonly || @read_only || a.read_only?
          yield a, :read
        else
          yield a, :rw
        end
      end
      @parent&.visit_callable_attrs(rdonly: true, &block)
    end

    def visit_callable_methods(&block)
      @node_def.method_defs.each(&block)
      p = @node_def.parent_node_def
      while p
        p.method_defs.each(&block)
        p = p.parent_node_def
      end
      @node_def.jdl_builder.global_methods_node_def.method_defs.each(&block)
    end

    def available(attrs_only: false)
      av = []
      visit_callable_attrs do |a, type|
        av << "#{a.name} (#{type})"
      end
      if !attrs_only
        visit_callable_methods do |m|
          av << m.name
        end
      end
      av.sort!
      av
    end

    def attr_or_method_not_found_error(name, errline: $last_call_location)
      av = available
      str = !av.empty? ? "\n#{av.join(", ")}" : " none"
      JABA.error("'#{name}' attr/method not defined. Available in this scope:#{str}", line: errline)
    end

    def attr_not_found_error(name, errline: $last_call_location)
      av = available(attrs_only: true)
      str = !av.empty? ? "\n#{av.join(", ")}" : " none"
      JABA.error("'#{name}' attribute not defined. Available in this scope:#{str}", line: errline)
    end

    def make_read_only
      @read_only = true
      if block_given?
        yield
        @read_only = false
      end
    end

    private

    def add_attr(attr_def)
      a = case attr_def.variant
        when :single
          AttributeSingle.new(attr_def, self)
        when :array
          AttributeArray.new(attr_def, self)
        when :hash
          AttributeHash.new(attr_def, self)
        end
      @attributes << a
      @attribute_lookup[attr_def.name] = a
    end
  end
end
