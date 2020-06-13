# frozen_string_literal: true

module JABA

  class TestChoiceAttribute < JabaTest

    it 'requires items to be set' do
      check_fail "'items' must be set", line: [ATTR_TYPES_JDL, 'fail "\'items\' must be set"'], trace: [__FILE__, 'tagA'] do
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
      check_fail 'Must be one of [1, 2, 3]', line: [ATTR_TYPES_JDL, 'fail "must be one of'], trace: [__FILE__, 'tagB'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :choice do # tagB
              items [1, 2, 3]
              default 4
            end
          end
        end
      end
      check_fail 'Must be one of [1, 2, 3]', line: [ATTR_TYPES_JDL, 'fail "must be one of'], trace: [__FILE__, 'tagC'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a, type: :choice do # tagC
              items [1, 2, 3]
              default [1, 2, 4]
            end
          end
        end
      end
    end

    it 'rejects invalid choices' do
      check_fail 'Must be one of [:a, :b, :c]', line: [ATTR_TYPES_JDL, 'fail "must be one of'], trace: [__FILE__, 'tagD'] do
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
      check_fail 'Must be one of [:a, :b, :c]', line: [ATTR_TYPES_JDL, 'fail "must be one of'], trace: [__FILE__, 'tagE'] do
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
    
  end

end
