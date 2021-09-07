# frozen_string_literal: true

module JABA

  class TestJabaType < JabaTest

    it 'can be flagged as a singleton' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagA)}: singleton type 'test' must be instantiated." do
        jaba(barebones: true) do
          type :test do # tagA
            singleton true
          end
        end
      end
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagB)}: singleton type 'test' must only be instantiated once." do
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
      assert_output 'def c;def a;def b;def a1;a;def b1;b;def c1;c;' do
        jaba(barebones: true) do
          type :c do
            dependencies [:b]
            print 'def c;'
            attr :c1 do
              print 'def c1;'
            end
          end
          type :a do
            print 'def a;'
            attr :a1 do
              print 'def a1;'
            end
          end
          type :b do
            print 'def b;'
            dependencies [:a]
            attr :b1 do
              print 'def b1;'
            end
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagF)}: \'a\' type contains a cyclic dependency on \'c\' type, \'b\' type." do
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
