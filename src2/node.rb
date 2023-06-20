module JABA
  class Node
    def initialize(node_def, id, src_loc, parent)
      JABA.error("node_def must not be nil") if node_def.nil?
      @node_def = node_def
      @api_obj = @node_def.api_class.new(self)
      @id = id
      @src_loc = src_loc # nil for root node. Updated dynamically in eval_jdl
      @attributes = []
      @attribute_lookup = KeyToSHash.new
      @attrs_to_ignore_when_setting = nil
      @attrs_to_ignore_when_getting = nil
      @children = []
      @read_only = false
      @parent = parent
      if parent
        parent.children << self
      end
    end

    def describe = "'#{node_def.name.inspect_unquoted}'"
    def id = @id
    def src_loc = @src_loc
    def src_dir = @src_loc.src_loc_info[0].parent_path
    def jdl___dir__ = src_dir
    def parent = @parent
    def children = @children
    def attributes = @attributes
    def [](name) = search_attr(name).value
    def has_attribute?(name) = @attribute_lookup.has_key?(name)

    def add_attrs(attr_defs)
      attr_defs.each do |d|
        add_attr(d)
      end
    end

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
    
    def ignore_attrs(set: nil, get: nil)
      @attrs_to_ignore_when_setting = set
      @attrs_to_ignore_when_getting = get
    end

    def ignore_attr_get?(name) = @attrs_to_ignore_when_getting&.has_key?(name)
    def ignore_attr_set?(name) = @attrs_to_ignore_when_setting&.has_key?(name)

    def node_def = @node_def
    def api_obj = @api_obj

    def eval_jdl(*args, called_from_jdl: true, **kwargs, &block)
      # Root node can be set from multiple files so update src_loc to block location.
      # All other nodes have a constant src_loc at time of creation.
      if root_node? && called_from_jdl
        sl = block.source_location
        @src_loc = "#{sl[0]}:#{sl[1]}"
      end
      do_jdl(called_from_jdl) do
        api_obj.instance_exec(*args, **kwargs, &block)
      end
    end

    def eval_jdl_str(str, file, called_from_jdl: true)
      # Root node can be set from multiple files so update src_loc first line of file
      # to be executed. All other nodes have a constant src_loc at time of creation.
      if root_node? && called_from_jdl
        @src_loc = "#{file}:1"
      end
      do_jdl(called_from_jdl) do
        api_obj.instance_eval(str, file)
      end
    end

    # Compound attrs don't have ids
    def compound_attr? = @id.nil?
    def root_node? = @parent.nil?

    def post_create
      @attributes.each do |a|
        if !a.set? && a.required?
          if a.attr_def.has_flag?(:node_option)
            JABA.error("#{describe} requires #{a.describe} to be passed in", errobj: self)
          else
            JABA.error("#{describe} requires #{a.describe} to be set", errobj: self)
          end
        end

        a.finalise

        # Note that it is still possible for attributes to not be marked as 'set' by this point, ie if the user never
        # set it and it didn't have a default. But by this point the set flag has served it purpose.
      end
    end

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

    # This is the only place that attrs values can be set or retrieved from user definitions.
    def jdl_process_attr(name, *args, __call_loc:, **kwargs, &block)
      is_get = (args.empty? && kwargs.empty? && !block_given?)
      if is_get
        return nil if ignore_attr_get?(name)
        a = search_attr(name)
        a.set_last_call_location(__call_loc) if JABA.context.executing_jdl?
        return a.value
      else
        return nil if ignore_attr_set?(name)
        a = get_attr(name, fail_if_not_found: false)
        if a
          a.set_last_call_location(__call_loc) if JABA.context.executing_jdl?
          if @read_only
            a.attr_error("#{a.describe} is read only in this scope")
          end
          a.set(*args, **kwargs, &block)
        else
          # if attr not found on this node search for it in parents. If found it is therefore
          # readonly. Issue a suitable error.
          a = search_attr(name, skip_self: true, fail_if_not_found: false)
          if a
            a.set_last_call_location(__call_loc) if JABA.context.executing_jdl?
            # Compound attributes are allowed to set 'sibling' attributes which are in its parent node
            if compound_attr? && a.node == @parent
              a.set(*args, **kwargs, &block)
            else
              a.attr_error("#{a.describe} is read only in this scope")
            end
          else
            attr_not_found_error(name)
          end
        end
        return nil
      end
    end

    def jdl_process_method(meth_def, block, *args, **kwargs)
      if meth_def.on_called
        return meth_def.on_called.call(*args, **kwargs, &block)
      else
        node_meth = "jdl_#{meth_def.name}"
        if respond_to?(node_meth)
          return send(node_meth, *args, **kwargs, &block)
        end
      end
      JABA.error("No method handler for #{name.inspect_unquoted} defined")
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

    def jdl_available = available

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

    def attr_or_method_not_found_error(name)
      av = available
      str = !av.empty? ? "\n#{av.join(", ")}" : " none"
      JABA.error("'#{name}' attr/method not defined. Available in this scope:#{str}")
    end

    def attr_not_found_error(name)
      av = available(attrs_only: true)
      str = !av.empty? ? "\n#{av.join(", ")}" : " none"
      JABA.error("'#{name}' attribute not defined. Available in this scope:#{str}")
    end

    def make_read_only
      @read_only = true
      if block_given?
        yield
        @read_only = false
      end
    end

    def jdl_clear(attr_name)
      a = get_attr(attr_name)
      if !a.attr_def.array? && !a.attr_def.hash?
        JABA.error("Only array and hash attributes can be cleared")
      end
      a.clear
    end

    def jdl_include(spec, **kwargs)
      if root_node?
        JABA.context.process_include(spec)
      else
        block = JABA.context.lookup_shared(spec)
        eval_jdl(**kwargs, &block)
      end
    end

    private

    def do_jdl(called_from_jdl)
      JABA.context.begin_jdl if called_from_jdl
      yield
    rescue ScriptError => e # script errors don't have a backtrace
      JABA.error(e.message, type: :script_error)
    rescue NameError => e
      JABA.error(e.message, line: e.backtrace[0])
    ensure
      JABA.context.end_jdl if called_from_jdl
    end
  end
end
