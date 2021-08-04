# frozen_string_literal: true

module JABA

  class TestChoiceAttribute < JabaTest

    it 'requires items to be set' do
      check_fail "'items' must be set", line: [__FILE__, 'tagA'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :choice # tagA
          end
        end
      end
    end

    it 'warns if items contains duplicates' do
      check_warn "'items' contains duplicates", __FILE__, 'tagK' do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :choice do # tagK
              items [:a, :a, :b, :b]
            end
          end
        end
      end
    end
    
    it 'requires default to be in items' do
      check_fail "Must be one of [1, 2, 3] but got '4'", line: [__FILE__, 'tagB'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :choice do
              items [1, 2, 3]
              default 4 # tagB
            end
          end
        end
      end
      check_fail "Must be one of [1, 2, 3] but got '4'", line: [__FILE__, 'tagC'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a, type: :choice do
              items [1, 2, 3]
              default [1, 2, 4] # tagC
            end
          end
        end
      end
    end

    it 'rejects invalid choices' do
      check_fail 'Must be one of [:a, :b, :c]', line: [__FILE__, 'tagD'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :choice do
              items [:a, :b, :c]
            end
          end
          test :t do
            a :d # tagD
          end
        end
      end
      check_fail 'Must be one of [:a, :b, :c]', line: [__FILE__, 'tagE'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a, type: :choice do
              items [:a, :b, :c]
            end
          end
          test :t do
            a [:a, :b, :c, :d] # tagE
          end
        end
      end
    end

    it 'can be set from the cmd line' do
      jaba(barebones: true, argv: [
        '-D', 'a1', 'b',
        '-D', 'a2', '',
        '-D', 'a3', '1']) do
        open_type :globals do
          attr :a1, type: :choice do
            items [:a, :b, :c]
            default :a
          end
          attr :a2, type: :choice do
            items [:a, :b, :c, nil]
            default :a
          end
          attr :a3, type: :choice do
            items [1, :a, 'b']
            default 'b'
          end
        end
        define :test
        test :t do
          globals.a1.must_equal :b
          globals.a2.must_be_nil
          globals.a3.must_equal 1
        end
      end

      op = jaba(barebones: true, argv: ['-D', 'a', 'd'], want_exceptions: false) do
        open_type :globals do
          attr :a, type: :choice do
            items [:a, :b, :c]
            default :a
          end
        end
      end
      op[:error].must_equal "'d' invalid value for 'a' attribute - [a|b|c] expected"
    end
  end

end
