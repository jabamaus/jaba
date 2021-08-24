# frozen_string_literal: true

module JABA

  class TestJabaType < JabaTest

    it 'can be flagged as a singleton' do
      check_fail "singleton type 'test' must be instantiated exactly once", line: [__FILE__, 'tagA'] do
        jaba(barebones: true) do
          type :test do # tagA
            singleton true
          end
        end
      end
      check_fail "singleton type 'test' must be instantiated exactly once", line: [__FILE__, 'tagB'] do
        jaba(barebones: true) do
          type :test do
            singleton true
          end
          test :t1
          test :t2 # tagB
        end
      end
    end

    it 'supports dependencies between types' do
      assert_output 'def a;def b;def c;a;b;c;' do
        jaba(barebones: true) do
          type :a do
            print 'def a;'
          end
          type :b do
            print 'def b;'
            dependencies [:a]
          end
          type :c do
            dependencies [:b]
            print 'def c;'
          end
          c :c do
            print 'c;' # evaluated third
          end
          a :a do
            print 'a;' # evaluated first
          end
          b :b do
            print 'b;' # evaluated second
          end
        end
      end
    end
    
    it 'checks for cyclic dependencies' do
      check_fail '\'a\' type contains a cyclic dependency on \'c\', \'b\'', line: [__FILE__, 'tagF'] do
        jaba(barebones: true) do
          type :a do # tagF
            dependencies :c
          end
          type :b do
            dependencies :a
          end
          type :c do
            dependencies :b
          end
        end
      end
    end
    
  end

end
