# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  module OS
    
    ##
    #
    def self.windows?
      true
    end
    
    ##
    #
    def self.mac?
      false
    end
    
  end

  ##
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

  ##
  #
  def self.generate_guid(namespace:, name:, braces: true)
    sha1 = ::Digest::SHA1.new
    sha1 << namespace << name
    a = sha1.digest.unpack("NnnnnN")
    a[2] = (a[2] & 0x0FFF) | (5 << 12)
    a[3] = (a[3] & 0x3FFF) | 0x8000
    uuid = "%08x-%04x-%04x-%04x-%04x%08x" % a
    uuid.upcase!
    uuid = "{#{uuid}}" if braces
    uuid.freeze
    uuid
  end

  ##
  #
  def self.milli_timer
    start_time = Time.now
    yield
    duration = Time.now - start_time
    millis = (duration * 1000).round(0)
    "#{millis}ms"
  end

  ##
  #
  module PropertyMethods

    @@id_to_var = {}

    PropertyInfo = Struct.new(:variant, :store_block)

    ##
    #
    def initialize(...)
      super
      @properties = {}
    end

    ##
    #
    def self.get_var(id)
      v = @@id_to_var[id]
      if !v
        v = "@#{id}"
        @@id_to_var[id] = v
      end
      v
    end

    ##
    #
    def define_property(p_id, variant: :single, store_block: false)
      case variant
      when :single
        do_define_property(p_id, :single, store_block, nil)
      when :array
        define_array_property(p_id, store_block: store_block)
      when :hash
        define_hash_property(p_id, store_block: store_block)
      when :block
        define_block_property(p_id)
      end
    end

    ##
    #
    def define_array_property(p_id, store_block: false)
      do_define_property(p_id, :array, store_block, [])
    end

    ##
    #
    def define_hash_property(p_id, store_block: false)
      do_define_property(p_id, :hash, store_block, {})
    end

    ##
    #
    def define_block_property(p_id)
      do_define_property(p_id, :block, true, nil)
    end

    ##
    #
    def set_property(p_id, val = nil, &block)
      info = @properties[p_id]
      if !info
        JABA.error("Failed to set undefined '#{p_id}' property")
      end

      inst_var = PropertyMethods.get_var(p_id)

      if block_given?
        if !val.nil?
          JABA.error('Must provide a value or a block but not both')
        end
        if info.store_block
          do_set(p_id, block) do
            instance_variable_set(inst_var, block)
          end
          return
        end
        val = block.call
      end
      
      if info.variant == :array
        if val.hash?
          JABA.error("'#{p_id}' expects an array but got '#{val}'")
        end
        current_val = instance_variable_get(inst_var)
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
      elsif info.variant == :hash
        if !val.hash?
          JABA.error("'#{p_id}' expects a hash but got '#{val}'")
        end
        current_val = instance_variable_get(inst_var)
        do_set(p_id, val) do
          current_val.merge!(val)
        end
      else
        if val.array? || val.hash?
          JABA.error("'#{p_id}' expects a single value but got '#{val}'")
        end
        do_set(p_id, val) do
          instance_variable_set(inst_var, val)
        end
      end
    end
    
    ##
    # Override in subclass to validate value. If property is an array will be called for each element.
    # Return :ignore to cancel property set
    #
    def pre_property_set(id, incoming_val)
    end

    ##
    # Override in subclass to validate value. If property is an array will be called for each element.
    #
    def post_property_set(id, incoming_val)
    end

    ##
    #
    def get_property(p_id)
      if !property_defined?(p_id)
        JABA.error("Failed to get undefined '#{p_id}' property")
      end
      instance_variable_get(PropertyMethods.get_var(p_id))
    end

    ##
    #
    def property_defined?(p_id)
      @properties.key?(p_id)
    end

    ##
    #
    def handle_property(p_id, val, &block)
      if val.nil? && !block_given?
        get_property(p_id)
      else
        set_property(p_id, val, &block)
      end
    end
    
    private

    ##
    #
    def do_define_property(p_id, variant, store_block, initial)
      if @properties.key?(p_id)
        JABA.error("'#{p_id}' property multiply defined")
      end
      @properties[p_id] = PropertyInfo.new(variant, store_block)

      var = PropertyMethods.get_var(p_id)
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

    ##
    #
    def do_set(p_id, val)
      if pre_property_set(p_id, val) != :ignore
        yield
        post_property_set(p_id, val)
      end
    end
  end
  
  ##
  #
  module HookMethods
    
    ##
    #
    def initialize(...)
      super
      @hooks = {}
    end

    ##
    #
    def define_hook(id, &block)
      if @hooks.key?(id)
        JABA.error("'#{id}' hook multiply defined")
      end
      hook = block_given? ? block : :not_set
      @hooks[id] = hook
    end

    ##
    #
    def hook_defined?(id)
      @hooks.key?(id)
    end

    ##
    #
    def set_hook(id, &block)
      if !hook_defined?(id)
        JABA.error("'#{id}' hook not defined")
      end
      on_hook_defined(id)
      @hooks[id] = block
    end

    ##
    #
    def call_hook(id, *args, receiver: self, fail_if_not_set: false, **keyval_args)
      block = @hooks[id]
      if !block
        JABA.error("'#{id}' hook not defined")
      elsif block == :not_set
        if fail_if_not_set
          JABA.error("'#{id}' not set - cannot call'")
        end
        return nil
      else
        receiver.eval_jdl(*args, **keyval_args, &block)
      end
    end

    ##
    #
    def on_hook_defined(id)
    end
    
  end

  ##
  #
  class FSM < OpenStruct
    
    ##
    #
    def initialize
      super
      @states = []
      @on_run = nil
      if block_given?
        yield self
        run
      end
    end

    ##
    #
    def add_state(klass, ...)
      s = klass.new
      fsm = self
      s.define_singleton_method(:fsm) do
        fsm
      end
      s.define_singleton_method(:goto) do |*args|
        fsm.goto(*args)
      end
      s.on_init(...) if s.respond_to?(:on_init)
      @states << s
    end

    ##
    #
    def on_run(&block)
      @on_run = block
    end

    ##
    #
    def goto(stateClass, ...)
      send_event(:exit)

      @current_state = @states.find{|s| s.class == stateClass}
      if @current_state.nil?
        JABA.error("'#{stateClass}' state not found")
      end

      send_event(:enter, ...)
    end
    
    ##
    #
    def send_event(event, ...)
      event_handler = "on_#{event}".to_sym
      if @current_state.respond_to?(event_handler)
        @current_state.send(event_handler, ...)
      end
    end

    ##
    #
    def run
      @current_state = @states.first
      send_event(:enter)
 
      if @on_run
        instance_eval(&@on_run)
      end

      send_event(:exit)
    end

  end

end
