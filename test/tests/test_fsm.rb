# frozen_string_literal: true

module JABA

  class TestFSM < JabaTest

    it 'calls on_init on all states' do
      assert_output 'a:on_init|b:on_init' do
        FSM.new do
          state :a do
            on_init do
              print 'a:on_init|'
            end
          end
          state :b do
            on_init do
              print 'b:on_init'
            end
          end
          state :c do
          end
        end
      end
    end

    it 'starts in specified state' do
      assert_output 'b:on_enter|b:on_exit' do
        FSM.new(initial: :b) do
          state :a do
            on_enter do
              print 'a:on_enter'
            end
          end
          state :b do
            on_enter do
              print 'b:on_enter|'
            end
            on_exit do
              print 'b:on_exit'
            end
          end
        end
      end
    end

    it 'supports transitions' do
      assert_output 'a:on_enter|a:on_exit|b:on_enter(1, 2, 3)|b:on_exit' do
        FSM.new do
          state :a do
            on_enter do
              print 'a:on_enter|'
              goto :b, 1, 2, 3
            end
            on_exit do
              print 'a:on_exit|'
            end
          end
          state :b do
            on_enter do |arg1, arg2, arg3|
              print "b:on_enter(#{arg1}, #{arg2}, #{arg3})|"
            end
            on_exit do
              print 'b:on_exit'
            end
          end
        end
      end
    end

    it 'supports events' do
      assert_output 'a:on_enter|a:on_event1(0)|a:on_event1(1)|a:on_exit|b:on_enter|b:on_event1(1)|b:on_event1(0)|b:on_exit|a:on_enter|a:on_exit|' do
        FSM.new(events: [:event1]) do
          state :a do
            on_enter  do
              print 'a:on_enter|'
            end
            on_exit do
              print 'a:on_exit|'
            end
            on_event1 do |n|
              print "a:on_event1(#{n})|"
              goto :b if n == 1
            end
          end
          state :b do
            on_enter do
              print 'b:on_enter|'
            end
            on_exit do
              print 'b:on_exit|'
            end
            on_event1 do |n|
              print "b:on_event1(#{n})|"
              goto :a if n == 0
            end
          end
          on_run do
            send_event(:event1, 0)
            send_event(:event1, 1)
            send_event(:event1, 1)
            send_event(:event1, 0)
          end
        end
      end
    end

  end

end
