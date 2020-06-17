# frozen_string_literal: true

module JABA

  class TestAttributeHash < JabaTest

    it 'defaults to empty hash' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a
        end
        test :t do
          a.must_equal({})
        end
      end
    end

    it 'can have a default' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a do
            default({k: :v})
          end
        end
        test :t do
          a[:k].must_equal(:v)
          a.must_equal({k: :v})
        end
      end
    end

    it 'validates that default is a hash' do
      check_fail "'a' attribute default must be a hash not a 'Array'", line: [__FILE__, 'tagU'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a do
              default [] # tagU
            end
          end
        end
      end
    end

    it 'works with block style default' do
      jaba(barebones: true) do
        define :test do
          attr :a
          attr :b
          attr_hash :c do
            default do
              {k1: a, k2: b}
            end
          end
        end
        test :t do
          a 1
          b 2
          c.must_equal({k1: 1, k2: 2})
        end
      end

      # test with hash attr default using an unset attr
      #
      check_fail "Cannot read uninitialised 'b' attribute", line: [__FILE__, 'tagI'] do
        jaba(barebones: true) do
          define :test do
            attr :a
            attr :b
            attr_hash :c do
              default do
                {k1: a, k2: b} # tagI
              end
            end
          end
          test :t do
            a 1
            c # TODO: this should be in trace
          end
        end
      end

      # test with another attr using unset hash attr
      #
      check_fail "Cannot read uninitialised 'a' hash attribute", line: [__FILE__, 'tagF'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a
            attr :b do
              default do
                a[:k] # tagF
              end
            end
          end
          test :t do
            b
          end
        end
      end
    end

    it 'can be set' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a
        end
        test :t do
          # Test basic set
          a :k, :v
          a[:k].must_equal(:v)
          
          # Overwrite value
          a :k, nil
          a[:k].must_be_nil
          
          # Overwrite back to original
          a :k, :v
          a[:k].must_equal(:v)
          
          # Add key
          a :k2, :v2
          a[:k2].must_equal(:v2)
        end
      end
    end

    it 'is not possible to modify returned hash' do
      check_fail 'Cannot modify read only value', line: [__FILE__, 'tagN'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a do
              default({k: :v})
            end
          end
          test :t do
            a[:k] = :v2 # tagN
          end
        end
      end
    end

    it 'considers setting to empty array as marking it as set' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a do
            flags :required
          end
        end
        test :t do
          a {}
        end
      end  
    end

    it 'can extend default' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a do
            default({k: :v})
          end
        end
        test :t do
          a :k2, :v2
          a.must_equal({k: :v, k2: :v2})
        end
      end
    end

    it 'allows setting value with block' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a
          attr :b, type: :choice do
            items [1, 2, 3]
          end
        end
        test :t do
          b 1
          a :key do
            case b
            when 1
              :yes
            else
              :no
            end
          end
          a[:key].must_equal :yes
        end
      end
    end

    it 'validates default element types are valid' do
      check_fail "'not a symbol' must be a symbol but was a 'String'",
                  line: [ATTR_TYPES_JDL, 'fail "\'#{value}\' must be a symbol but was a'], trace:[__FILE__, 'tagD'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, type: :symbol do # tagD
              default({k: :v, k2: 'not a symbol'})
            end
          end
        end
      end
    end

    it 'validates element types are valid' do
      check_fail "'not a symbol' must be a symbol but was a 'String'",
                 line: [ATTR_TYPES_JDL, 'fail "\'#{value}\' must be a symbol but was a'], trace: [__FILE__, 'tagE'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, type: :symbol
          end
          test :t do
            a :k, :v
            a :k2, 'not a symbol' # tagE
          end
        end
      end
    end

    it 'disallows :nosort' do
      check_fail "'a' attribute failed validation: ':nosort' flag is incompatible: :nosort is only allowed on array attributes",
                line: [__FILE__, 'tagQ'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a do # tagQ
              flags :nosort
            end
          end
        end
      end
    end
    
    it 'disallows :allow_dupes' do
      check_fail "'a' attribute failed validation: ':allow_dupes' flag is incompatible: :allow_dupes is only allowed on array attributes",
                 line: [__FILE__, 'tagP'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a do # tagP
              flags :allow_dupes
            end
          end
        end
      end
    end
    
    it 'can accept flag options' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a do
            flag_options :f1, :f2, :f3
          end
        end
        test :t do
          a :k, :v, :f1, :f2
          generate do
            a = get_attr(:a)
            elem = a.fetch(:k)
            elem.value.must_equal(:v)
            elem.has_flag_option?(:f1).must_equal(true)
            elem.has_flag_option?(:f2).must_equal(true)
            elem.has_flag_option?(:f3).must_equal(false)
            elem.flag_options.must_equal [:f1, :f2]
          end
        end
      end
    end

    it 'can accept value options' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a do
            value_option :kv1
            value_option :kv2
          end
        end
        test :t do
          a :k, :v, kv1: 'a', kv2: 'b'
          generate do
            a = get_attr(:a)
            elem = a.fetch(:k)
            elem.value.must_equal(:v)
            elem.get_option_value(:kv1).must_equal('a')
            elem.get_option_value(:kv2).must_equal('b')
          end
        end
      end
    end

    it 'can accept value and flag options' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a do
            value_option :kv1
            value_option :kv2
            flag_options [:flag_opt1, :flag_opt2, :flag_opt3]
          end
        end
        test :t do
          a :k, :v, :flag_opt1, :flag_opt2, kv1: 'a', kv2: 'b'
          generate do
            a = get_attr(:a)
            elem = a.fetch(:k)
            elem.value.must_equal(:v)
            elem.has_flag_option?(:flag_opt1).must_equal(true)
            elem.has_flag_option?(:flag_opt2).must_equal(true)
            elem.has_flag_option?(:flag_opt3).must_equal(false)
            elem.flag_options.must_equal [:flag_opt1, :flag_opt2]
            elem.get_option_value(:kv1).must_equal('a')
            elem.get_option_value(:kv2).must_equal('b')
          end
        end
      end
    end

    it 'validates a value is given' do
      check_fail("'a' hash attribute requires a key and a value", line: [__FILE__, 'tagM']) do
        jaba(barebones: true) do
          define :test do
            attr_hash :a
          end
          test :t do
            a :key # tagM
          end
        end
      end
    end

    # TODO: test wipe
    
  end

end
