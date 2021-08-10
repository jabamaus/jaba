# frozen_string_literal: true

module JABA

  class TestIntAttribute < JabaTest

    it 'validates default' do
      check_fail ':int attributes only accept integer values', line: [__FILE__, 'tagP'] do
        jaba(barebones: true) do
          type :test do
            attr :a, type: :int do
              default 'not an int' # tagP
            end
          end
        end
      end
    end

    it 'validates value' do
      check_fail ':int attributes only accept integer values', line: [__FILE__, 'tagW'] do
        jaba(barebones: true) do
          type :test do
            attr :a, type: :int
          end
          test :t do
            a true # tagW
          end
        end
      end
    end

    it 'fails if value not supplied when :required flag specified' do
      check_fail "'t.a' attribute requires a value", line: [__FILE__, 'tagY'] do
        jaba(barebones: true) do
          type :test do
            attr :a, type: :bool do
              flags :required
            end
          end
          test :t # tagY
        end
      end
    end

    it 'supports standard ops' do
      jaba(barebones: true) do
        type :test do
          attr :a, type: :int
          attr :b, type: :int do
            default 1
          end
          attr_array :aa, type: :int
          attr_array :ba, type: :int do
            default [3, 4, 5]
          end
          attr_hash :ah, type: :int, key_type: :symbol
          attr_hash :bh, type: :int, key_type: :symbol do
            default({k1: 1})
          end
        end
        test :t do
          a.must_equal(0) # Defaults to 0 if :required flag not used
          b.must_equal(1) # Works with a default
          a 2
          a.must_equal(2)
          b 3
          b.must_equal(3)

          # test array attrs
          aa.must_equal []
          aa [1, 2, 3]
          aa.must_equal [1, 2, 3]
          ba.must_equal [3, 4, 5]
          ba [6, 7, 8]
          ba.must_equal [3, 4, 5, 6, 7, 8]

          # test hash attrs
          ah.must_equal({})
          ah :k1, 1
          ah.must_equal({k1: 1})
          bh.must_equal({k1: 1})
          bh :k1, 2
          bh.must_equal({k1: 2})
          bh :k2, 3
          bh.must_equal({k1: 2, k2: 3})
        end
      end
    end

    it 'can be set from the cmd line' do
      jaba(barebones: true, argv: [
        '-D', 'a1', '1',
        '-D', 'a2', '3433409',
        '-D', 'a3', '-1',
        '-D', 'a4', '0']) do
        open_type :globals do
          attr :a1, type: :int
          attr :a2, type: :int 
          attr :a3, type: :int
          attr :a4, type: :int
        end
        type :test
        test :t do
          globals.a1.must_equal(1)
          globals.a2.must_equal(3433409)
          globals.a3.must_equal(-1)
          globals.a4.must_equal(0)
        end
      end

      op = jaba(barebones: true, argv: ['-D', 'a', 'foo'], want_exceptions: false) do
        open_type :globals do
          attr :a, type: :int
        end
      end
      op[:error].must_equal "'foo' invalid value for 'a' attribute - integer expected"
    end

  end

end
