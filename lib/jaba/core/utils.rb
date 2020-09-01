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
  def self.profile(enabled)
    if !enabled
      yield
      return
    end

    begin
      require 'ruby-prof'
    rescue LoadError
      puts "ruby-prof gem is required to run with --profile. Could not be loaded."
      exit 1
    end

    puts 'Invoking ruby-prof...'
    RubyProf.start
    yield
    result = RubyProf.stop
    file = "#{JABA.temp_dir}/jaba.profile"
    str = String.new
    puts "Write profiling results to #{file}..."
    [RubyProf::FlatPrinter, RubyProf::GraphPrinter].each do |p|
      printer = p.new(result)
      printer.print(str)
    end
    IO.write(file, str)
  end

  ##
  #
  module PropertyMethods

    @@id_to_var = {}

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
    def define_property(p_id, val = nil)
      if @properties.key?(p_id)
        JABA.error("'#{p_id}' property multiply defined")
      end
      @properties[p_id] = nil
      var = PropertyMethods.get_var(p_id)
      instance_variable_set(var, val)

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
    def define_array_property(p_id, val = [])
      define_property(p_id, val)
    end

    ##
    #
    def set_property(p_id, val = nil, &block)
      if !@properties.key?(p_id)
        JABA.error("Failed to set undefined '#{p_id}' property")
      end

      if block_given?
        if !val.nil?
          JABA.error('Must provide a default value or a block but not both')
        end
        val = block
        if pre_property_set(p_id, val) != :ignore
          instance_variable_set(PropertyMethods.get_var(p_id), val)
          post_property_set(p_id, val)
        end
      else
        current_val = instance_variable_get(PropertyMethods.get_var(p_id))
        if current_val.array?
          val = if val.array?
                  val.flatten # don't flatten! as might be frozen
                else
                  Array(val)
                end
          val.each do |elem|
            if pre_property_set(p_id, elem) != :ignore
              current_val << elem
              post_property_set(p_id, elem)
            end
          end
        else
          # Fail if setting a single value property as an array, unless its the first time. This is to allow
          # a property to become either single value or array, depending on how it is first initialised.
          #
          if !current_val.nil? && val.array?
            JABA.error("'#{p_id}' property cannot accept an array")
          end
          if pre_property_set(p_id, val) != :ignore
            instance_variable_set(PropertyMethods.get_var(p_id), val)
            post_property_set(p_id, val)
          end
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
      if !@properties.key?(p_id)
        JABA.error("Failed to get undefined '#{p_id}' property")
      end
      instance_variable_get(PropertyMethods.get_var(p_id))
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
  class FSM

    ##
    #
    def initialize(initial: nil, events: nil, &block)
      super()
      JABA.error('block required') if !block_given?
      @states = []
      @events = Array(events)
      @on_run = nil
      instance_eval(&block)
      @current = initial ? get_state(initial) : @states.first
      @current.send_event(:enter)
      instance_eval(&@on_run) if @on_run
      @current.send_event(:exit)
    end

    ##
    #
    def state(id, &block)
      @states << FSMState.new(self, id, @events, &block)
    end

    ##
    #
    def on_run(&block)
      @on_run = block
    end

    ##
    #
    def send_event(id, *args)
      @current.send_event(id, *args)
    end

  private

    ##
    #
    def goto(id, *args)
      @current.send_event(:exit)
      @current = get_state(id)
      @current.send_event(:enter, *args)
    end

    ##
    #
    def get_state(id)
      s = @states.find{|s| s.id == id}
      JABA.error("'#{id}' state not defined") if !s
      s
    end

  end

  ##
  #
  class FSMState
    
    attr_reader :id

    ##
    #
    def initialize(fsm, id, events, &block)
      super()
      @fsm = fsm
      @id = id
      @event_to_block = {}
      define_event(:init)
      define_event(:enter)
      define_event(:exit)
      events.each do |event|
        define_event(event)
      end
      instance_eval(&block)
      send_event(:init)
    end

    ##
    #
    def define_event(event)
      define_singleton_method("on_#{event}") do |&block|
        @event_to_block[event] = block
      end
    end

    ##
    #
    def send_event(id, *args)
      block = @event_to_block[id]
      if block
        block.call(*args)
      end
    end

    ##
    #
    def goto(id, *args)
      @fsm.send(:goto, id, *args)
    end

  end

end
