# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class FSM

    ##
    #
    def initialize(initial: nil, events: nil, &block)
      super()
      raise 'block required' if !block_given?
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
      raise "'#{id}' state not defined" if !s
      s
    end

  end

  ##
  #
  class FSMState
    
    include HookMethods

    attr_reader :id

    ##
    #
    def initialize(fsm, id, events, &block)
      super()
      @fsm = fsm
      @id = id
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
      id = "on_#{event}".to_sym
      define_hook(id)
      define_singleton_method(id) do |&block|
        set_hook(id, &block)
      end
    end

    ##
    #
    def send_event(id, *args)
      call_hook("on_#{id}".to_sym, *args)
    end

    ##
    #
    def goto(id, *args)
      @fsm.send(:goto, id, *args)
    end

  end

end
