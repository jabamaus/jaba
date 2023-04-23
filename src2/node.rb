module JABA
  # Attriute lookup hash converts keys to symbols so can lookup with strings or symbols
  class AttributeLookupHash < Hash
    def [](key) = super(key.to_sym)
    def []=(key, value); super(key.to_sym, value); end
  end

  class Node
    def initialize(api_klass, id, src_loc, parent)
      JABA.error("api_klass must not be nil") if api_klass.nil?
      @api_klass = api_klass
      @id = id
      @src_loc = src_loc
      @attributes = []
      @attribute_lookup = AttributeLookupHash.new
      @children = []
      @read_only = false
      @parent = parent
      @parent.children << self if @parent
      api_klass.each_attr_def do |d|
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

    def api_obj = @api_klass.singleton.__internal_set_node(self)
    def eval_jdl(...) = api_obj.instance_exec(...)

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
          JABA.error("#{a.describe} is read only in this context", line: $last_call_location)
        end
        a.set(*args, **kwargs, &block)
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

    # TODO: include methods
    def available
      attrs = []
      visit_callable_attrs do |a, type|
        attrs << "#{a.name} (#{type})"
      end
      attrs.sort!
      attrs
    end

    def attr_not_found_error(name, errline: nil)
      str = !available.empty? ? "\n#{available.join(", ")}" : " none"
      JABA.error("'#{name}' attribute or method not defined. Available in this context:#{str}", line: errline)
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
