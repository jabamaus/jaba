module JABA
  # Attriute lookup hash converts keys to symbols so can lookup with strings or symbols
  class AttributeLookupHash < Hash
    def [](key) = super(key.to_sym)
    def []=(key, value); super(key.to_sym, value); end
  end

  class Node
    def initialize(api_klass, id, src_loc, parent)
      @api_klass = api_klass
      @id = id
      @src_loc = src_loc
      @attributes = []
      @attribute_lookup = AttributeLookupHash.new
      @children = []
      @read_only = false
      set_parent(parent)
      if api_klass
        api_klass.attr_defs.each do |d|
          a = case d.variant
            when :single
              AttributeSingle.new(d, self)
            when :array
              AttributeArray.new(d, self)
            when :hash
              AttributeHash.new(d, self)
            end
          @attributes << a
          @attribute_lookup[d.name] = a
        end
      end
    end

    def eval_jdl(...)
      @api_klass.singleton.__internal_set_node(self)
      @api_klass.singleton.instance_exec(...)
    end

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

    def set_parent(parent)
      if @parent
        @parent.children.delete(self)
      end
      @parent = parent
      if @parent
        @parent.children << self
      end
    end

    def children = @children

    def visit(&block)
      yield self
      @children.each do |c|
        c.visit(&block)
      end
    end

    def attributes = @attributes

    def get_attr(name, fail_if_not_found: true)
      a = @attribute_lookup[name]
      if !a && fail_if_not_found
        attr_not_found_error(name)
      end
      a
    end

    def [](name) = get_attr(name).value

    def search_attr(name, fail_if_not_found: true)
      a = get_attr(name, fail_if_not_found: false)
      if !a
        if @parent
          a = @parent.search_attr(name, fail_if_not_found: false)
        end
      end
      if !a && fail_if_not_found
        attr_not_found_error(name)
      end
      a
    end

    def handle_attr(name, *args, **kwargs, &block)
      is_get = (args.empty? && kwargs.empty? && !block_given?)
      if is_get
        a = search_attr(name)
        return a.value
      else
        a = get_attr(name)
        if @read_only
          JABA.error("#{a.describe} is read only in this context", want_backtrace: false)
        end
        a.set(*args, **kwargs, &block)
        return nil
      end
    end

    def visit_callable_attrs(rdonly: false, &block)
      @attributes.each do |a|
        if rdonly || a.read_only?
          yield a, :rdonly
        else
          yield a, :rw
        end
      end
      if @parent
        @parent.visit_callable_attrs(rdonly: true, &block)
      end
    end

    def attr_not_found_error(name)
      rdonly = []
      rw = []
      visit_callable_attrs do |a, type|
        case type
        when :rw
          rw << a
        when :rdonly
          rdonly << a
        end
      end
      JABA.error("'#{name}' attribute not found. The following attributes are available in this context:\n\n  " \
      "Read/write:\n    #{rw.map { |a| a.name }.join(", ")}\n\n  " \
      "Read only:\n    #{rdonly.map { |a| a.name }.join(", ")}\n\n")
    end

    def make_read_only
      @read_only = true
      if block_given?
        yield
        @read_only = false
      end
    end
  end
end
