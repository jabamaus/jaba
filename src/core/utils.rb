module JABA
  class DebuggableBasicObject < BasicObject
    def instance_variables = []
    def class = DebuggableBasicObject
    def inspect = 'DebuggableBasicObject'
  end

  module OS
    def self.windows? = true
    def self.mac? = false
  end

  def self.error(msg, errobj: nil, callstack: nil, syntax: false, want_backtrace: true)
    e = JabaError.new(msg)
    e.instance_variable_set(:@callstack, Array(errobj&.src_loc || callstack || caller))
    e.instance_variable_set(:@syntax, syntax)
    e.instance_variable_set(:@want_backtrace, want_backtrace)
    raise e
  end

  def self.make_api_class(api_module)
    api_class = Class.new(JDL_Base)
    api_module.public_instance_methods.each do |m|
      if m !~ /^(jdl_(.*))$/
        raise "All API module methods must start with jdl_" # Don't use JABA.error as JABAError class not yet defined
      end
      delegate = Regexp.last_match(1)
      api_method = Regexp.last_match(2)
      api_class.define_method(api_method) do |*args, **keyval_args, &block|
        $last_call_location = ::Kernel.caller_locations(1, 1)[0]
        @obj.send(delegate, *args, **keyval_args, &block)
      end
    end
    api_class
  end

  # Convert a file path specified in user definitions to an absolute path.
  # If a path starts with ./ it is taken as being relative to the directory the jaba file is in, else it is
  # made absolute based on the supplied base dir (unless absolute already).
  #
  def self.spec_to_absolute_path(spec, base_dir, node)
    abs_path = if (spec.absolute_path? || spec.start_with?('$('))
      spec
    elsif spec.start_with?('./')
      "#{node.source_dir}#{spec.delete_prefix('.')}"
    else
      "#{base_dir}/#{spec}"
    end
    abs_path.cleanpath
  end

  def self.milli_timer
    start_time = Time.now
    yield
    duration = Time.now - start_time
    millis = (duration * 1000).round(0)
    "#{millis}ms"
  end

  module PropertyMethods
    PropertyInfo = Struct.new(:variant, :type, :var, :store_block, :last_call_location)

    def initialize(...)
      super
      @properties = {}
    end

    def define_property(p_id, variant:, type: nil, store_block: false)
      case variant
      when :single
        define_single_property(p_id, type: type, store_block: store_block)
      when :array
        define_array_property(p_id, type: type, store_block: store_block)
      when :hash
        define_hash_property(p_id, type: type, store_block: store_block)
      end
    end

    def define_single_property(p_id, type: nil, store_block: false)
      do_define_property(p_id, :single, type, store_block, nil)
    end

    def define_array_property(p_id, type: nil, store_block: false)
      do_define_property(p_id, :array, type, store_block, [])
    end

    def define_hash_property(p_id, type: nil, store_block: false)
      do_define_property(p_id, :hash, type, store_block, {})
    end

    def set_property_from_jdl(p_id, val = nil, &block)
      set_property(p_id, val, __jdl_call_loc: $last_call_location, &block)
    end

    def set_property(p_id, val = nil, __jdl_call_loc: nil, &block)
      info = get_property_info(p_id)

      if __jdl_call_loc
        info.last_call_location = __jdl_call_loc
      end

      if block_given?
        if !val.nil? && info.variant != :hash
          JABA.error('Must provide a value or a block but not both')
        end
        if info.store_block
          do_set(p_id, block) do
            instance_variable_set(info.var, block)
          end
          return
        end

        val = if info.type == :block
          if info.variant == :hash
            {val => block}
          else
            block
          end
        else
          yield
        end
      end
      
      case info.variant
      when :single
        if val.array? || val.hash?
          JABA.error("'#{p_id}' expects a single value but got '#{val}'")
        end
        do_set(p_id, val) do
          instance_variable_set(info.var, val)
        end
      when :array
        if val.hash?
          JABA.error("'#{p_id}' expects an array but got '#{val}'")
        end
        current_val = instance_variable_get(info.var)
        vals = if val.array?
          val.flatten # don't flatten! as might be frozen
        else
          Array(val)
        end
        vals.each do |val|
          do_set(p_id, val) do
            current_val << val
          end
        end
      when :hash
        if !val.hash?
          JABA.error("'#{p_id}' expects a hash but got '#{val}'")
        end
        current_val = instance_variable_get(info.var)
        do_set(p_id, val) do
          current_val.merge!(val)
        end
      end
    end
    
    # Override in subclass to validate value. If property is an array will be called for each element.
    # Return :ignore to cancel property set
    #
    def pre_property_set(id, incoming_val) ; end

    # Override in subclass to validate value. If property is an array will be called for each element.
    #
    def post_property_set(id, incoming_val) ; end

    def get_property(p_id)
      info = get_property_info(p_id)
      instance_variable_get(info.var)
    end

    def property_defined?(p_id)
      get_property_info(p_id, fail_if_not_found: false) != nil
    end

    def handle_property_from_jdl(p_id, val, &block)
      if val.nil? && !block_given?
        get_property(p_id)
      else
        set_property_from_jdl(p_id, val, &block)
      end
    end
    
    def property_last_call_loc(p_id)
      info = get_property_info(p_id)
      info.last_call_location
    end

    def property_validation_error(p_id, msg)
      JABA.error(msg, callstack: property_last_call_loc(p_id) || src_loc)
    end

    def property_validation_warning(p_id, msg)
      services.jaba_warn(msg, callstack: property_last_call_loc(p_id) || src_loc)
    end

  private

    def get_property_info(p_id, fail_if_not_found: true)
      info = @properties[p_id]
      if !info && fail_if_not_found
        JABA.error("'#{p_id}' property undefined")
      end
      info
    end

    def do_define_property(p_id, variant, type, store_block, initial)
      if @properties.key?(p_id)
        JABA.error("'#{p_id}' property multiply defined")
      end
      var = "@#{p_id}"
      @properties[p_id] = PropertyInfo.new(variant, type, var, store_block, nil)

      instance_variable_set(var, initial)

      # Core classes like JabaAttributeDefinition define their own attr_reader methods to retrieve property values
      # in the most efficient way possible. If one has not been defined dynamically define an accessor.
      #
      if !respond_to?(p_id)
        define_singleton_method p_id do
          instance_variable_get(var)
        end
      end
    end

    def do_set(p_id, val)
      if pre_property_set(p_id, val) != :ignore
        yield
        post_property_set(p_id, val)
      end
    end
  end
end
