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
    def initialize(initial: nil, events: nil)
      super()
      @states = []
      @events = Array(events)
      @on_run = nil
      yield self if block_given?
      @current = initial ? get_state(initial) : @states.first
      @current.call_hook(:on_enter)
      instance_eval(&@on_run) if @on_run
      @current.call_hook(:on_exit)
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
    def goto(id, *args)
      @current.call_hook(:on_exit)
      @current = get_state(id)
      @current.call_hook(:on_enter, *args)
    end

    ##
    #
    def send_event(id, *args)
      @current.call_hook("on_#{id}".to_sym, *args)
    end

  private

    ##
    #
    def get_state(id)
      s = @states.find{|s| s.id == id}
      if !s
        raise "'#{id}' state not defined"
      end
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
      define_hook(:on_init)
      define_hook(:on_enter)
      define_hook(:on_exit)
      events.each do |event|
        define_hook("on_#{event}".to_sym)
      end
      instance_eval(&block)
      call_hook(:on_init)
    end

    ##
    #
    def goto(id, *args)
      @fsm.goto(id, *args)
    end

    ##
    #
    def method_missing(id, &block)
      set_hook(id, &block)
    end

  end

end
