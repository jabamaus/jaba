# frozen_string_literal: true

module JABA

  class TestAttributeArray < JabaTest

    it 'allows setting a default array' do
      jaba do
        define :test do
          attr_array :a do
            default [1, 2, 3]
          end
        end
        test :t do
          generate do
            a.must_equal [1, 2, 3]
          end
        end
      end
    end
    
    it 'strips duplicates by default' do
      jaba do
        define :test do
          attr_array :a do
          end
        end
        test :t do
          a [5, 5, 6, 6, 7, 7, 7]
          a.must_equal [5, 5, 6, 6, 7, 7, 7]
          generate do
            a.must_equal [5, 6, 7]
          end
        end
      end
      # TODO: turn into check_warn util
      # op.warnings.must_equal(["Warning at TestAttributeArray.rb:6: 'a' array attribute contains duplicates"])
    end
    
    it 'allows flagging arrays with :allow_dupes' do
      jaba do
        define :test do
          attr_array :a do
            flags :allow_dupes
          end
        end
        test :t do
          a [5, 5, 6, 6, 7, 7, 7]
          generate do
            a.must_equal [5, 5, 6, 6, 7, 7, 7]
          end
        end
      end
    end
    
    it 'sorts by default' do
      jaba do
        define :test do
          attr_array :a do
          end
          attr_array :b do
          end
          attr_array :c do
          end
          attr_array :d do
          end
        end
        test :t do
          a [5, 4, 2, 1, 3]
          b ['e', 'c', 'a', 'A', 'C']
          c [10.34, 3, 800.1, 0.01, -1]
          d [:e, :c, :a, :A, :C]
          generate do
            a.must_equal [1, 2, 3, 4, 5]
            b.must_equal ['a', 'A', 'c', 'C', 'e']
            c.must_equal [-1, 0.01, 3, 10.34, 800.1]
            d.must_equal [:a, :A, :c, :C, :e]
          end
        end
      end
    end
    
    it 'does not sort or strip duplicates from bool arrays' do
      jaba do
        define :test do
          attr_array :a, type: :bool do
          end
        end
        test :t do
          a [true, false, false, true]
          generate do
            a.must_equal [true, false, false, true]
          end
        end
      end
    end
    
    it 'allows flagging arrays as unordered' do
      jaba do
        define :test do
          attr_array :a do
            flags :unordered, :allow_dupes
          end
        end
        test :t do
          a ['j', 'a', 'b', 'a']
          generate do
            a.must_equal ['j', 'a', 'b', 'a']
          end
        end
      end
    end
    
    it 'supports prefix and postfix options' do
      jaba do
        define :test do
          attr_array :a do
            flags :unordered, :allow_dupes
          end
        end
        test :t do
          a ['j', 'a', 'b', 'a'], prefix: '1', postfix: 'z'
          generate do
            a.must_equal ['1jz', '1az', '1bz', '1az']
          end
        end
      end
    end
    
    it 'only allows prefix/postfix on string elements' do
      check_fails('Prefix/postfix option can only be used with arrays of strings', trace: [__FILE__, '# tag1']) do
        jaba do
          define :test do
            attr_array :a do
            end
          end
          test :t do
            a [1, 2, 3], prefix: 'a', postfix: 'b' # tag1
          end
        end
      end
    end
    
    it 'supports excluding elements' do
      jaba do
        define :test do
          attr_array :a do
          end
          attr_array :b do
          end
        end
        test :t do
          a :a
          a [:b], exclude: [:c]
          a [:c, :d, :e], exclude: [:d, :e]
          b [1, 2, 3, 4]
          b exclude: [2, 3]
          generate do
            a.must_equal [:a, :b]
            b.must_equal [1, 4]
          end
        end
      end
    end

    it 'supports :prefix and :postfix in conjunction with :exclude' do
      jaba do
        define :test do
          attr_array :a do
            flags :unordered
          end
        end
        test :t do
          a ['abc', 'acc', 'adc', 'aec']
          a exclude: ['c', 'd'], prefix: 'a', postfix: 'c'
          generate do
            a.must_equal ['abc', 'aec']
          end
        end
      end
    end
    
    it 'supports excluding elements with regexes' do
      jaba do
        define :test do
          attr_array :a do
          end
        end
        test :t do
          a ['one', 'two', 'three', 'four']
          a exclude: [/o/, 'three']
          generate do
            a.must_equal []
          end
        end
      end
    end
    
    it 'fails if excluding with regex on non-strings' do
      check_fails('Exclude regex can only operate on strings', trace: [__FILE__, '# tag2']) do
        jaba do
          define :test do
            attr_array :a do
            end
          end
          test :t do
            a [1, 2, 3, 4, 43], exclude: [/3/] # tag2
          end
        end
      end
    end
    
    it 'supports conditional excluding' do
      jaba do
        define :test do
          attr_array :a do
          end
          attr_array :b do
          end
        end
        test :t do
          a [:a]
          a [:b, :c], exclude: ->(e) {e == :e}
          a [:d, :e], exclude: ->(e) {e == :d or e == :c}
          b [1, 2, 3, 4], exclude: ->(e) {e > 2}
          generate do
            a.must_equal [:a, :b]
            b.must_equal [1, 2]
          end
        end
      end
    end
    
    it 'supports clearing arrays' do
      jaba do
        define :test do
          attr_array :a do
          end
          attr :b do
            default 1
          end
        end
        test :t do
          a [1, 2]
          a 3
          a [4, 5]
          a.must_equal [1, 2, 3, 4, 5]
          b 2
          b.must_equal(2)
          wipe :a, :b
          a.must_equal []
          b.must_equal 1
        end
      end
    end
    
    it 'supports clearing excludes' do
    end
    
  end

end
