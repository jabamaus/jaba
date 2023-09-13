module JABA
  class Node
    def init(node_def, sibling_id, src_loc, parent)
      JABA.error("node_def must not be nil") if node_def.nil?
      @node_def = node_def
      @api_obj = @node_def.api_class.new(self)
      
      def @api_obj.singleton_method_added(id)
        if id != :singleton_method_added
          JABA.error("Ruby method definitions are not allowed. Use 'method' at file scope", line: ::Kernel.calling_location)
        end
      end

      @sibling_id = sibling_id
      @src_loc = src_loc # nil for root node. Updated dynamically in eval_jdl
      @attributes = []
      @attribute_lookup = KeyToSHash.new
      @children = []
      @read_only = false
      @parent = parent
      if parent && !compound_attr?
        sibling = parent.get_child(sibling_id, fail_if_not_found: false)
        if sibling && sibling.node_def.name == @node_def.name
          JABA.error("'#{sibling_id.inspect_unquoted}' is not unique amongst '#{@node_def.name}' node types. See previous at #{sibling.src_loc.src_loc_describe}", line: src_loc)
        end
        parent.children << self
      end
    end

    # Never freeze a node. Freeze can get called as a consequence of replacing a string attr value
    # with a node (eg when expanding dependencies). We never want the whole node to be frozen.
    def freeze = self
    def describe = "'#{node_def.name.inspect_unquoted}'"
    def sibling_id = @sibling_id
    def src_loc = @src_loc
    def src_file = @src_loc.src_loc_info[0] 
    def src_dir = src_file.parent_path
    def jdl___dir__ = src_dir

    def parent = @parent
    def children = @children

    def get_child(sibling_id, fail_if_not_found: true)
      sibling_id = sibling_id.to_s
      child = @children.find { |c| c.sibling_id.to_s == sibling_id }
      if child.nil? && fail_if_not_found
        JABA.error("'#{sibling_id.inspect_unquoted}' child not found in #{describe} node")
      end
      child
    end

    def attributes = @attributes
    def attr_value(name) = search_attr(name).value 
    def [](name) = attr_value(name)
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

    def remove_attr(name)
      if !has_attribute?(name)
        JABA.error("Cannot remove '#{name.inspect_unquoted}' attribute - not found")
      end
      i = @attributes.find_index{|a| a.name == name}
      if i.nil?
        JABA.error("Failed to find '#{name.inspect_unquoted}' attribute index")
      end
      @attributes.delete_at(i)
      @attribute_lookup.delete(name)
    end

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
    def compound_attr? = @sibling_id.nil?
    def root_node? = @parent.nil?

    def post_create
      @attributes.each do |a|
        if !a.set? && a.required?
          JABA.error("#{describe} requires #{a.describe} to be set", errobj: self)
        end
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
      is_get = (args.empty? && kwargs.empty? && !block)
      if is_get
        a = search_attr(name)
        if JABA.context.executing_jdl?
          a.set_last_call_location(__call_loc)
        end
        return a.value
      else
        a = get_attr(name, fail_if_not_found: false)
        if a
          if JABA.context.executing_jdl?
            a.set_last_call_location(__call_loc)
          end
          if @read_only
            a.attr_error("#{a.describe} is read only in this scope")
          end
          a.set(*args, **kwargs, &block)
        else
          # if attr not found on this node search for it in parents. If found it is therefore
          # readonly. Issue a suitable error.
          a = search_attr(name, skip_self: true, fail_if_not_found: false)
          if a
            if JABA.context.executing_jdl?
              a.set_last_call_location(__call_loc)
            end
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

    def pull_up(attr)
      # TODO: check for commonality
      ca = @children[0].get_attr(attr.name)
      attr.set_last_call_location(ca.last_call_location)

      ca.visit_elem do |elem, key|
        if attr.attr_def.variant == :hash
          attr.set(key, elem.value, *elem.flag_options, __map: false, **elem.value_options_raw)
        else
          attr.set(elem.value, *elem.flag_options, __map: false, **elem.value_options_raw)
        end
      end
      @children.each do |c|
        c.remove_attr(attr.name)
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
        next if compound_attr? && a.name == node_def.name # ensure compound cannot call itself recursively
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

    def jdl_include(spec, *args, **kwargs)
      if root_node?
        JABA.context.process_include(spec)
      else
        block = JABA.context.lookup_shared(spec)
        eval_jdl(*args, **kwargs, &block)
      end
    end

    # TODO: move out
    def import_exports(from_node)
      virtual = from_node[:virtual]
      # Skip single value attributes as they cannot export. The reason for this is that exporting it would simply
      # overwrite the destination attribute creating a conflict. Which node should control the value? For this
      # reason disallow.
      #
      from_node.attributes.each do |from_attr|
        next if from_attr.attr_def.single?
        next if from_attr.attr_def.has_flag?(:node_option)
        attr = nil

        # visit all attribute elements in array/hash
        #
        from_attr.visit_elem do |elem, key|
          if elem.attr_def.has_flag?(:exportable)
            if elem.has_flag_option?(:export) || elem.has_flag_option?(:export_only) || virtual
              # Get the corresponding attr in this project node. This will always be a hash or an array.
              attr ||= get_attr(elem.name)

              foptions = elem.flag_options.dup
              foptions.delete_if { |fo| fo == :export || fo == :export_only }

              # Pass __map: false as the values have already been mapped
              case attr.attr_def.variant
              when :array
                attr.set(elem.raw_value, *foptions, __map: false, **elem.value_options_raw)
              when :hash
                attr.set(key, elem.raw_value, *foptions, __map: false, **elem.value_options_raw)
              else
                JABA.error("Unhandled variant '#{variant.inspect_unquoted}'")
              end
            end
          elsif virtual
            from_attr.attr_warn("Non-exportable #{from_attr.describe} ignored")
          end
        end
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

  class TargetNode < Node
    def pre_create_configs
      @root = attr_value(:root)
      @virtual = attr_value(:virtual)
    end

    def root = @root
    def virtual? = @virtual
    def each_config(&block) = @children.each(&block)

    def get_matching_config(cfg_node)
      src_target = cfg_node.parent
      cfg_id = cfg_node.sibling_id
      # Try an exact match first
      cfg = get_child(cfg_id, fail_if_not_found: false)
      return cfg if cfg
      # If not found try a unique substring match
      matches = []
      @children.each do |c|
        if c.sibling_id =~ /#{cfg_id}/i || cfg_id =~ /#{c.sibling_id}/i
          matches << c
        end
      end
      return matches.first if matches.size == 1
      if matches.size > 1
        JABA.error("Found multiple matches") # TODO: improve
      end
      JABA.error("In #{src_target.sibling_id}->#{sibling_id} dependency could not find a config in '#{sibling_id}' to match '#{cfg_id.inspect_unquoted}'. Available: [#{@children.map{|c| c.sibling_id}.join(',')}]", line: src_loc)
    end

    def process_deps
      get_attr(:deps).each do |attr|
        dep_node = attr.value
        link = !attr.has_flag_option?(:nolink) && !dep_node.virtual?
        import_exports(dep_node)
        each_config do |cfg_node|
          dep_cfg_node = dep_node.get_matching_config(cfg_node)
          cfg_node.import_exports(dep_cfg_node)
          if link
            case dep_cfg_node[:type]
            when :lib
              if cfg_node[:type] != :lib
                cfg_node.get_attr(:libs).set("#{dep_cfg_node[:libdir]}/#{dep_cfg_node[:targetname]}#{dep_cfg_node[:targetext]}")
              end
            when :dll
              if cfg_node[:type] != :lib
                # TODO: only if targeting visual studio
                il = dep_cfg_node[:vcimportlib]
                if il # dlls don't always have import libs - eg plugins
                  cfg_node.get_attr(:libs).set("#{dep_cfg_node[:libdir]}/#{il}")
                end
              end
            end
          end
        end
      end
    end
  end
end
