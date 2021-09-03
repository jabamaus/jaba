# frozen_string_literal: true

module JABA

  class TestAttributeArray < JabaTest

    it 'supports a default' do
      # It validates default is an array or single value
      #
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagV)}: 'default' expects an array but got '{:a=>:b}'.", trace: [__FILE__, :tagv] do
        jaba(barebones: true) do
          type :test do
            attr_array :a do # tagv
              default({a: :b}) # tagV
            end
          end
        end
      end

      # It validates default is an array when block form is used
      #
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagO)}: 't.a' array attribute default requires an array not a 'Integer'." do
        jaba(barebones: true) do
          type :test do
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagD)}: 'a' array attribute default invalid: 'not a symbol' must be a symbol but was a 'String'.",
           trace: [__FILE__, :tagd] do
        jaba(barebones: true) do
          type :test do
            attr_array :a, type: :symbol do # tagd
              default ['not a symbol'] # tagD
            end
          end
        end
      end

      # It validates default elements respect attribute type when block form used
      #
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagW)}: 't.a' array attribute invalid: 'not a symbol' must be a symbol but was a 'String'." do
        jaba(barebones: true) do
          type :test do
            attr_array :a, type: :symbol do # tagW
              default do
                ['not a symbol']
              end
            end
          end
          test :t # need an instance of test in order for block style defaults to be called
        end
      end

      # TODO: test flag/value options
      jaba(barebones: true) do
        type :test do
          attr_array :a
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
          a.must_equal [] # defaults to empty array
          b.must_equal [1, 2, 3]
          c.must_equal [4, 5, 6]
          d.must_equal [1, 2, 3, 4, 5, 6]
          d [7, 8] # default array values are appended to not overwritten when block style used
          d 9
          d.must_equal [1, 2, 3, 4, 5, 6, 7, 8, 9]
          e [9] # default array values are appended to not overwritten when value style used
          e.must_equal [7, 8, 9]
        end
      end
    end

    it 'checks for accessing uninitialised attributes' do
      # test with array attr default using an unset attr
      #
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagI)}: Cannot read uninitialised 't.b' attribute - it might need a default value.", trace: [__FILE__, :tagi] do
        jaba(barebones: true) do
          type :test do
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
            c # tagi
          end
        end
      end

      # test with another attr using unset array attr
      #
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagF)}: Cannot read uninitialised 't.a' array attribute - it might need a default value.", trace: [__FILE__, :tagf] do
        jaba(barebones: true) do
          type :test do
            attr_array :a
            attr :b do
              default do
                a[0] # tagF
              end
            end
          end
          test :t do
            b # tagf
          end
        end
      end
    end

    it 'allows setting value with block' do
      jaba(barebones: true) do
        type :test do
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagN)}: Cannot modify read only value." do
        jaba(barebones: true) do
          type :test do
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
        type :test do
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
      line = find_line_number(__FILE__, 'tagL')
      check_warn("Stripping duplicate '5' from 't.a' array attribute. See previous at test_attribute_array.rb:#{line}", __FILE__, 'tagU') do
        jaba(barebones: true) do
          type :test do
            attr_array :a # Duplicates will be stripped by default
            attr_array :b do
              flags :allow_dupes
            end
            attr_array :c, type: :bool
            attr_array :d, type: :string
          end
          test :t do
            a [5] # tagL
            a [5, 6, 6, 7, 7, 7, 8] # tagU
            a.must_equal [5, 6, 7, 8]
            b [5, 5, 6, 6, 7, 7, 7] # duplicates allowed
            b.must_equal [5, 5, 6, 6, 7, 7, 7]
            c [true, false, false, true] # Never strips duplicates in bool arrays
            c.must_equal [true, false, false, true]
            d ['aa', 'ab', 'ac']
            d ['a', 'b', 'c'], prefix: 'a' # Test duplicates caused by prefix still stripped
            d.must_equal ['aa', 'ab', 'ac']
          end
        end
      end
    end
    
    it 'handles sorting' do
      jaba(barebones: true) do
        type :test do
          attr_array :a
          attr_array :b
          attr_array :c
          attr_array :d
          attr_array :e, type: :bool
          attr_array :f do
            flags :no_sort
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
            attrs.f.must_equal [5, 4, 3, 2, 1] # unsorted due to :no_sort
          end
        end
      end
    end

    it 'validates element types are valid' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagT)}: 't.a' array attribute invalid: :bool attributes only accept [true|false] but got 'true'." do
        jaba(barebones: true) do
          type :test do
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
        type :test do
          attr_array :a do
            flags :no_sort, :allow_dupes
          end
        end
        test :t do
          a ['j', 'a', 'b', 'a'], prefix: '1', postfix: 'z'
          a.must_equal ['1jz', '1az', '1bz', '1az']
        end
      end
    end
    
    it 'only allows prefix/postfix on string elements' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagQ)}: When setting 't.a' array attribute prefix/postfix option can only be used with string arrays." do
        jaba(barebones: true) do
          type :test do
            attr_array :a
          end
          test :t do
            a [1, 2, 3], prefix: 'a', postfix: 'b' # tagQ
          end
        end
      end
    end
    
    it 'supports deleting elements' do
      jaba(barebones: true) do
        type :test do
          attr_array :a
        end
        test :t do
          a [:a, :b], delete: [:a, :b]
          a.must_equal []
          a [:c, :d, :e]
          a delete: :d
          a delete: :e
          a.must_equal [:c]
          a delete: :c
          a.must_equal []

          a [1, 2, 3, 4]
          a delete: [2, 3]
          a.must_equal [1, 4]
          a delete: 1
          a delete: 4
          a.must_equal []

          # delete works with prefix and postfix options
          #
          a ['abc', 'acc', 'adc', 'aec']
          a delete: ['c', 'd'], prefix: 'a', postfix: 'c'
          a.must_equal ['abc', 'aec']
          a delete: ['abc', 'aec']
          a.must_equal []

          # delete works with regexes
          #
          a ['one', 'two', 'three', 'four']
          a delete: [/o/, 'three']
          a.must_equal []

          a [:one, :two, :three, :four]
          a delete: [/o/, :three]
          a.must_equal []

          # deletion can be conditional
          #
          a [:a, :b, :c, :d, :e]
          a delete: ->(e) {(e == :d) || (e == :c)}
          a.must_equal [:a, :b, :e]
          a delete: ->(e) {true}
          a.must_equal []
          a [1, 2, 3, 4], delete: ->(e) {e > 2}
          a.must_equal [1, 2]
        end
      end
    end

    it 'fails if deleting with regex on non-strings' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagR)}: Deletion using a regex can only operate on strings or symbols." do
        jaba(barebones: true) do
          type :test do
            attr_array :a
          end
          test :t do
            a [1, 2, 3, 4, 43], delete: [/3/] # tagR
          end
        end
      end
    end

    it 'warns if nothing deleted' do
      check_warn "'[7, 8]' did not match any elements - nothing removed", __FILE__, :tagH do
        jaba(barebones: true) do
          type :test do
            attr_array :a
          end
          test :t do
            a [1, 2, 3, 4, 43], delete: [7, 8] # tagH
          end
        end
      end
    end
    
    it 'supports wiping arrays' do
      jaba(barebones: true) do
        type :test do
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
        type :test do
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagS)}: 'b' attribute not found. Available: [:a]" do
        jaba(barebones: true) do
          type :test do
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
        type :test do
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
    
    it 'supports setting a validator' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagB)}: 't.a' array attribute invalid: failed.", trace: [__FILE__, :tagb] do
        jaba(barebones: true) do
          type :test do
            attr_array :a do
              validate do |val|
                if val == 'invalid'
                  fail 'failed' # tagB
                end
              end
            end
          end
          test :t do
            a ['val']
            a ['invalid'] # tagb
          end
        end
      end
    end

    it 'supports on_set hook' do
      jaba(barebones: true) do
        type :test do
          attr_array :a do
            # on_set executed in context of node so all attributes available
            on_set do |new_val|
              b "#{new_val}_b"
            end
          end
          attr_array :b do
            # new value can be taken from block arg
            on_set do |new_val|
              c "#{new_val}_c"
            end
          end
          attr :c
        end
        test :t do
          a [1, 2]
          b.must_equal ['1_b', '2_b']
          c.must_equal '2_b_c'
        end
      end
    end

  end

end
