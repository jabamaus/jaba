class StateA
  def on_init(val)
    print "a:on_init(#{val})|"
  end
  def on_enter
    print 'a:on_enter|'
  end
  def on_exit
    print 'a:on_exit|'
  end
  def on_event1(n)
    print "a:on_event1(#{n})|"
    goto StateB if n == 1
  end
end

class StateB
  def on_init
    print 'b:on_init|'
  end
  def on_enter
    print 'b:on_enter|'
  end
  def on_exit
    print 'b:on_exit|'
  end
  def on_event1(n)
    print "b:on_event1(#{n})|"
    goto StateA if n == 0
  end
end

class StateC
  def on_enter
    print 'c:on_enter|'
    goto StateD, 1, 2
  end
  def on_exit
    print 'c:on_exit|'
  end
end

class StateD
  def on_enter(arg1, arg2)
    print "d:on_enter(#{arg1}, #{arg2})|"
  end
  def on_exit
    print 'd:on_exit|'
  end
end

class StateE
  def on_enter
    print "e:on_enter|var1=#{fsm.var1}|var2=#{fsm.var2}|"
  end
end

class TestFsm < JabaTest

  it 'starts in first state' do
    assert_output 'a:on_init(1)|b:on_init|a:on_enter|a:on_exit|' do
      JABA::FSM.new do |fsm|
        fsm.add_state(StateA, 1)
        fsm.add_state(StateB)
        fsm.add_state(StateC)
      end
    end
  end

  it 'supports transitions' do
    assert_output 'c:on_enter|c:on_exit|d:on_enter(1, 2)|d:on_exit|' do
      JABA::FSM.new do |fsm|
        fsm.add_state(StateC)
        fsm.add_state(StateD)
      end
    end
  end

  it 'supports events' do
    assert_output 'a:on_init(1)|b:on_init|a:on_enter|a:on_event1(0)|a:on_event1(1)|a:on_exit|b:on_enter|b:on_event1(1)|b:on_event1(0)|b:on_exit|a:on_enter|a:on_exit|' do
      JABA::FSM.new do |fsm|
        fsm.add_state(StateA, 1)
        fsm.add_state(StateB)
        fsm.on_run do
          send_event(:event1, 0)
          send_event(:event1, 1)
          send_event(:event1, 1)
          send_event(:event1, 0)
        end
      end
    end
  end

  it 'supports variables' do
    assert_output 'e:on_enter|var1=1|var2=[1, 2]|' do
      JABA::FSM.new do |fsm|
        fsm.add_state(StateE)
        fsm.var1 = 1
        fsm.var2 = [1, 2]
      end
    end
  end
end
