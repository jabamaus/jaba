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
            attrs.a.must_equal [1, 2, 3]
          end
        end
      end
    end
    
    it 'strips duplicates by default' do
      jaba do
        define :test do
          attr_array :a
        end
        test :t do
          a [5, 5, 6, 6, 7, 7, 7]
          a.must_equal [5, 5, 6, 6, 7, 7, 7]
          generate do
            attrs.a.must_equal [5, 6, 7]
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
            attrs.a.must_equal [5, 5, 6, 6, 7, 7, 7]
          end
        end
      end
    end
    
    it 'sorts by default' do
      jaba do
        define :test do
          attr_array :a
          attr_array :b
          attr_array :c
          attr_array :d
        end
        test :t do
          a [5, 4, 2, 1, 3]
          b ['e', 'c', 'a', 'A', 'C']
          c [10.34, 3, 800.1, 0.01, -1]
          d [:e, :c, :a, :A, :C]
          generate do
            attrs.a.must_equal [1, 2, 3, 4, 5]
            attrs.b.must_equal ['a', 'A', 'c', 'C', 'e']
            attrs.c.must_equal [-1, 0.01, 3, 10.34, 800.1]
            attrs.d.must_equal [:a, :A, :c, :C, :e]
          end
        end
      end
    end
    
    it 'does not sort or strip duplicates from bool arrays' do
      jaba do
        define :test do
          attr_array :a, type: :bool
        end
        test :t do
          a [true, false, false, true]
          generate do
            attrs.a.must_equal [true, false, false, true]
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
            attrs.a.must_equal ['j', 'a', 'b', 'a']
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
            attrs.a.must_equal ['1jz', '1az', '1bz', '1az']
          end
        end
      end
    end
    
    it 'only allows prefix/postfix on string elements' do
      check_fail 'Prefix/postfix option can only be used with arrays of strings', trace: [__FILE__, '# tag1'] do
        jaba do
          define :test do
            attr_array :a
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
          attr_array :a
          attr_array :b
        end
        test :t do
          a :a
          a [:b], exclude: [:c]
          a [:c, :d, :e], exclude: [:d, :e]
          b [1, 2, 3, 4]
          b exclude: [2, 3]
          generate do
            attrs.a.must_equal [:a, :b]
            attrs.b.must_equal [1, 4]
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
            attrs.a.must_equal ['abc', 'aec']
          end
        end
      end
    end
    
    it 'supports excluding elements with regexes' do
      jaba do
        define :test do
          attr_array :a
        end
        test :t do
          a ['one', 'two', 'three', 'four']
          a exclude: [/o/, 'three']
          generate do
            attrs.a.must_equal []
          end
        end
      end
    end
    
    it 'fails if excluding with regex on non-strings' do
      check_fail 'Exclude regex can only operate on strings', trace: [__FILE__, '# tag2'] do
        jaba do
          define :test do
            attr_array :a
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
          attr_array :a
          attr_array :b
        end
        test :t do
          a [:a]
          a [:b, :c], exclude: ->(e) {e == :e}
          a [:d, :e], exclude: ->(e) {(e == :d) || (e == :c)}
          b [1, 2, 3, 4], exclude: ->(e) {e > 2}
          generate do
            attrs.a.must_equal [:a, :b]
            attrs.b.must_equal [1, 2]
          end
        end
      end
    end
    
    it 'supports clearing arrays' do
      jaba do
        define :test do
          attr_array :a
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
    
    it 'gives a copy of options to each element' do
      jaba do
        opt = 'opt'
        arg = 'arg'
        define :test do
          attr_array :a do
            keyval_options :opt
          end
        end
        test :t do
          a 1, arg, opt: opt
          a 2, arg, opt: opt
          generate do
            a = get_attr(:a)
            
            e0 = a.get_elem(0)
            e0.get.must_equal(1)
            opt0 = e0.key_value_options[:opt]
            opt0.must_equal('opt')
            arg0 = e0.options[0]
            arg0.must_equal('arg')
            
            e1 = a.get_elem(1)
            e1.get.must_equal(2)
            opt1 = e1.key_value_options[:opt]
            opt1.must_equal('opt')
            arg1 = e1.options[0]
            arg1.must_equal('arg')
            
            opt0.object_id.wont_equal(opt1.object_id)
            arg0.object_id.wont_equal(arg1.object_id)
          end
        end
      end
    end
    
  end

end
