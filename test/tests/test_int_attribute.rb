# frozen_string_literal: true

module JABA

  class TestIntAttribute < JabaTest

    describe 'failure conditions' do

      it 'validates default' do
        check_fail ':int attributes only accept integer values', line: [__FILE__, 'tagP'] do
          jaba(barebones: true) do
            define :test do
              attr :b, type: :int do
                default 'not an int' # tagP
              end
            end
          end
        end
      end

      it 'validates value' do
        check_fail ':int attributes only accept integer values', line: [__FILE__, 'tagW'] do
          jaba(barebones: true) do
            define :test do
              attr :c, type: :int
            end
            test :b do
              c true # tagW
            end
          end
        end
      end

    end

    it 'works with default values' do
      jaba(barebones: true) do
        define :test do
          attr :a, type: :int
          attr :b, type: :int do
            default 1
          end
        end
        test :t do
          a.must_equal(0) # Defaults to 0 if :required flag not used
          b.must_equal(1)
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

  end

end
