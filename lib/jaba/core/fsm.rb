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
