# frozen_string_literal: true

module JABA

  class TestBoolAttribute < JabaTest

    it 'defaults to false' do
      jaba(barebones: true) do
        define :test do
          attr :a, type: :bool
        end
        test :t do
          a.must_equal(false)
        end
      end
    end

    it 'requires default to be true or false' do
      check_fail ':bool attributes only accept [true|false] but got \'1\'', line: [__FILE__, 'tagP'] do
        jaba(barebones: true) do
          define :test do
            attr :b, type: :bool do
              default 1 # tagP
            end
          end
        end
      end
      jaba(barebones: true) do
        define :test do
          attr :b, type: :bool do
            default true
          end
          attr :c, type: :bool do
            default false
          end
        end
        test :t do
          b.must_equal(true)
          c.must_equal(false)
        end
      end
    end

    it 'only allows boolean values' do
      check_fail ':bool attributes only accept [true|false]', line: [__FILE__, 'tagW'] do
        jaba(barebones: true) do
          define :test do
            attr :c, type: :bool do
              default true
            end
          end
          test :b do
            c 1 # tagW
          end
        end
      end
      jaba do
        define :test do
          attr :b, type: :bool do
            default true
          end
          attr :c, type: :bool do
            default false
          end
        end
        test :t do
          b false
          c true
          b.must_equal(false)
          c.must_equal(true)
        end
      end
    end
    
    it 'works with :required flag' do
      check_fail "'t.a' attribute requires a value", line: [__FILE__, 'tagY'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :bool do
              flags :required
            end
          end
          test :t do # tagY
          end
        end
      end
    end

    it 'can be set from the cmd line' do
      jaba(barebones: true, argv: [
        '-D', 'a1', 'true',
        '-D', 'a2', 'false',
        '-D', 'a3', '1',
        '-D', 'a4', '0']) do
        open_type :globals do
          attr :a1, type: :bool do
            default false
          end
          attr :a2, type: :bool do
            default true
          end
          attr :a3, type: :bool do
            default false
          end
          attr :a4, type: :bool do
            default true
          end
        end
        define :test
        test :t do
          globals.a1.must_equal true
          globals.a2.must_equal false
          globals.a3.must_equal true
          globals.a4.must_equal false
        end
      end

      op = jaba(barebones: true, argv: ['-D', 'a', '10'], want_exceptions: false) do
        open_type :globals do
          attr :a, type: :bool
        end
      end
      op[:error].must_equal "'10' invalid value for 'a' attribute - [true|false|0|1] expected"
    end

  end

end
