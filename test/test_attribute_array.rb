# frozen_string_literal: true

module JABA

  class TestAttributeArray < JabaTest

    it 'supports a default' do
      check_fail "'a' array attribute default must be an array", line: [__FILE__, 'tagV'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a do
              default 1 # tagV
            end
          end
        end
      end
      check_fail "'a' array attribute requires an array", line: [__FILE__, 'tagO'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a do # tagO
              default do
                1
              end
            end
          end
          test :t # need an instance of test in order for block style defaults to be called
        end
      end
      
      # It validates default elements respect attribute type
      #
      check_fail "'not a symbol' must be a symbol but was a 'String'",
                 line: [ATTR_TYPES_JDL, 'fail "\'#{value}\' must be a symbol but was a'], trace: [__FILE__, 'tagD'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a, type: :symbol do # tagD
              default ['not a symbol'] # TODO: validate immediately to get better error line
            end
          end
        end
      end

      # It validates default elements respect attribute type when block form used
      #
      check_fail "'not a symbol' must be a symbol but was a 'String'",
                 line: [ATTR_TYPES_JDL, 'fail "\'#{value}\' must be a symbol but was a'], trace: [__FILE__, 'tagW'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a, type: :symbol do # tagW
              default do
                ['not a symbol']
              end
            end
          end
          test :t # need an intance of test in order for block style defaults to be called
        end
      end

      jaba(barebones: true) do
        define :test do
          attr_array :b do
            default [1, 2, 3] # value style default
          end
          attr_array :c do
            default do # block style default
              [4, 5, 6]
            end
          end
          attr_array :d do
            default do # block style default referencing other attrs
              b + c
            end
          end
          attr_array :e do
            default [7, 8]
          end
        end
        test :t do
          b.must_equal [1, 2, 3]
          c.must_equal [4, 5, 6]
          d.must_equal [1, 2, 3, 4, 5, 6]
          e [9] # default array values are appended to not overwritten
          e.must_equal [7, 8, 9]
        end
      end
    end

    it 'works with block style default' do
      # test with array attr default using an unset attr
      #
      check_fail "Cannot read uninitialised 'b' attribute", line: [__FILE__, 'tagI'] do
        jaba(barebones: true) do
          define :test do
            attr :a
            attr :b
            attr_array :c do
              default do
                [a, b] # tagI
              end
            end
          end
          test :t do
            a 1
            c # TODO: this should be in trace
          end
        end
      end

      # test with another attr using unset array attr
      #
      check_fail "Cannot read uninitialised 'a' attribute", line: [__FILE__, 'tagF'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a
            attr :b do
              default do
                a[0] # tagF
              end
            end
          end
          test :t do
            b
          end
        end
      end
    end

    it 'allows setting value with block' do
      jaba(barebones: true) do
        define :test do
          attr_array :a
          attr :b
          attr :c
          attr :d
        end
        test :t do
          b 1
          c 2
          d 3
          a do
            val = []
            val << b if b < 2
            val << c if c > 3
            val << d if d == 3
            val
          end
          a.must_equal [1, 3]
        end
      end
    end
    
    it 'is not possible to modify returned array' do
      check_fail 'Cannot modify read only value', line: [__FILE__, 'tagN'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a do
              default([:a])
            end
          end
          test :t do
            a << :b # tagN
          end
        end
      end
    end

    it 'considers setting to empty array as marking it as set' do
      jaba(barebones: true) do
        define :test do
          attr_array :a do
            flags :required
          end
        end
        test :t do
          a []
        end
      end  
    end

    it 'handles duplicates' do
      check_warn("Stripping duplicate '5'", __FILE__, 'tagU') do
        jaba(barebones: true) do
          define :test do
            attr_array :a # Duplicates will be stripped by default
            attr_array :b do
              flags :allow_dupes
            end
            attr_array :c, type: :bool
          end
          test :t do
            a [4, 5, 5, 6, 6, 7, 7, 7, 8] # tagU
            a.must_equal [4, 5, 6, 7, 8]
            b [5, 5, 6, 6, 7, 7, 7] # duplicates allowed
            b.must_equal [5, 5, 6, 6, 7, 7, 7]
            c [true, false, false, true] # Never strips duplicates in bool arrays
            c.must_equal [true, false, false, true]
          end
        end
      end
    end
    
    it 'handles sorting' do
      jaba(barebones: true) do
        define :test do
          attr_array :a
          attr_array :b
          attr_array :c
          attr_array :d
          attr_array :e, type: :bool
          attr_array :f do
            flags :nosort
          end
        end
        test :t do
          a [5, 4, 2, 1, 3]
          b ['e', 'c', :a, 'a', 'A', :C] # sorts case-insensitively
          c [10.34, 3, 800.1, 0.01, -1]
          d [:e, :c, :a, :A, :C]
          e [true, false, false, true] # never sorts a bool array
          e.must_equal [true, false, false, true]
          f [5, 4, 3, 2, 1]
          generate do
            attrs.a.must_equal [1, 2, 3, 4, 5]
            attrs.b.must_equal [:a, 'a', 'A', 'c', :C, 'e']
            attrs.c.must_equal [-1, 0.01, 3, 10.34, 800.1]
            attrs.d.must_equal [:a, :A, :c, :C, :e]
            attrs.f.must_equal [5, 4, 3, 2, 1] # unsorted due to :nosort
          end
        end
      end
    end

    it 'validates element types are valid' do
      check_fail ':bool attributes only accept [true|false]', 
                 line: [ATTR_TYPES_JDL, 'fail ":bool attributes only accept'], trace: [__FILE__, 'tagT'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a, type: :bool
          end
          test :t do
            a [true, false, false, true]
            a ['true'] # tagT
          end
        end
      end
    end
    
    it 'supports prefix and postfix options' do
      jaba(barebones: true) do
        define :test do
          attr_array :a do
            flags :nosort, :allow_dupes
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
      check_fail 'Prefix/postfix option can only be used with arrays of strings', line: [__FILE__, 'tagQ'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a
          end
          test :t do
            a [1, 2, 3], prefix: 'a', postfix: 'b' # tagQ
          end
        end
      end
    end
    
    it 'supports excluding elements' do
      jaba(barebones: true) do
        define :test do
          attr_array :a
          attr_array :b
        end
        test :t do
          a [:a]
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
      jaba(barebones: true) do
        define :test do
          attr_array :a do
            flags :nosort
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
      jaba(barebones: true) do
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
      check_fail 'Exclude regex can only operate on strings', line: [__FILE__, 'tagR'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a
          end
          test :t do
            a [1, 2, 3, 4, 43], exclude: [/3/] # tagR
          end
        end
      end
    end
    
    it 'supports conditional excluding' do
      jaba(barebones: true) do
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
    
    it 'supports wiping arrays' do
      jaba(barebones: true) do
        define :test do
          attr_array :a
          attr :b do
            default 1
          end
        end
        test :t do
          a [1, 2]
          a [3]
          a [4, 5]
          a.must_equal [1, 2, 3, 4, 5]
          b 2
          b.must_equal(2)
          wipe :a, :b
          a.must_equal []
          b.must_equal 1
          a [3, 4]
          b 3
          a.must_equal [3, 4]
          b.must_equal 3
          wipe [:a, :b]
          a.must_equal []
          b.must_equal 1
        end
      end
    end
    
    it 'supports wiping default array' do
      jaba(barebones: true) do
        define :test do
          attr_array :a do
            default [1, 2]
          end
          attr_array :b do
            default [5, 6]
          end
        end
        test :t do
          wipe :a
          a [3, 4]
          b [7, 8]

          a.must_equal [3, 4]
          b.must_equal [5, 6, 7, 8]
        end
      end
    end

    it 'catches invalid args to wipe' do
      check_fail "'b' attribute not found", line: [__FILE__, 'tagS'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a
          end
          test :t do
            a [1, 2, 3, 4, 43]
            wipe :b # tagS
          end
        end
      end
    end

    it 'supports clearing excludes' do
    end
    
    # TODO: test flag option copies

    it 'gives a copy of keyval options to each element' do
      jaba(barebones: true) do
        opt1 = 'opt1'
        opt2 = 'opt2'
        define :test do
          attr_array :a do
            value_option :opt1
            value_option :opt2
          end
        end
        test :t do
          a [1, 2], opt1: opt1, opt2: opt2
          a [3], opt1: opt1, opt2: opt2
          generate do
            a = get_attr(:a)
            
            attr = a.at(0)
            attr.value.must_equal(1)
            opt1val = attr.get_option_value(:opt1)
            opt1val.wont_be_nil
            opt1val.object_id.wont_equal(opt1.object_id)
            opt1val.must_equal('opt1')
            opt2val = attr.get_option_value(:opt2)
            opt2val.wont_be_nil
            opt2val.object_id.wont_equal(opt2.object_id)
            opt2val.must_equal('opt2')

            attr = a.at(1)
            attr.value.must_equal(2)
            opt1val = attr.get_option_value(:opt1)
            opt1val.wont_be_nil
            opt1val.object_id.wont_equal(opt1.object_id)
            opt1val.must_equal('opt1')
            opt2val = attr.get_option_value(:opt2)
            opt2val.wont_be_nil
            opt2val.object_id.wont_equal(opt2.object_id)
            opt2val.must_equal('opt2')

            attr = a.at(2)
            attr.value.must_equal(3)
            opt1val = attr.get_option_value(:opt1)
            opt1val.wont_be_nil
            opt1val.object_id.wont_equal(opt1.object_id)
            opt1val.must_equal('opt1')
            opt2val = attr.get_option_value(:opt2)
            opt2val.wont_be_nil
            opt2val.object_id.wont_equal(opt2.object_id)
            opt2val.must_equal('opt2')
          end
        end
      end
    end
    
  end

end