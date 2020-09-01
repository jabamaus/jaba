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
