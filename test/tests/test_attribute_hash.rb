# frozen_string_literal: true

module JABA

  class TestAttributeHash < JabaTest

    it 'supports a default' do
      jaba(barebones: true) do
        define :test do
          attr :single1 do
            default 1
          end
          attr :single2
          attr_hash :a, key_type: :symbol do
            flag_options :opt1, :opt2
          end
          attr_hash :b, key_type: :symbol do
            default({k: :v}) # value style default
            flag_options :opt1, :opt2
            value_option :vopt
          end
          attr_hash :c, key_type: :symbol do
            default do # block style default
              { k1: 1, k2: 2 }
            end
            flag_options :opt1, :opt2
          end
          attr_hash :d, key_type: :symbol do
            default do # block style default that references other attributes
              { k1: single1, k2: single2 }
            end
            flag_options :opt1, :opt2
          end
        end
        test :t do
          a.must_equal({})
          
          b[:k].must_equal(:v)
          b.must_equal({k: :v})

          c.must_equal({k1: 1, k2: 2})

          single2 2
          d.must_equal({k1: 1, k2: 2})

          # test that defaults can be overridden
          #
          single1 3
          single1.must_equal(3)

          a :k, :v, :opt1
          a.must_equal({k: :v})

          b :k, :v3, :opt1 # keep same key but overwrite value
          b :k2, :v2, :opt1, vopt: 1
          b :k3, :v3, :opt2
          b.must_equal({k: :v3, k2: :v2, k3: :v3}) # New key value gets merged in with default

          c :k3, :v3, :opt1
          c :k4, :v4, :opt2
          c.must_equal({k1: 1, k2: 2, k3: :v3, k4: :v4}) # New key value gets merged in with default when block form used

          d :k3, :v3, :opt2
          d :k4, :v4, :opt1
          d.must_equal({k1: 3, k2: 2, k3: :v3, k4: :v4})
          generate do
            a = get_attr(:a)
            a.fetch(:k).has_flag_option?(:opt1).must_equal(true)
            b = get_attr(:b)
            b.fetch(:k).has_flag_option?(:opt1).must_equal(true)
            b.fetch(:k2).has_flag_option?(:opt1).must_equal(true)
            b.fetch(:k2).get_option_value(:vopt).must_equal(1)
            b.fetch(:k3).has_flag_option?(:opt2).must_equal(true)
            c = get_attr(:c)
            c.fetch(:k1).has_flag_option?(:opt1).must_equal(true)
            c.fetch(:k2).has_flag_option?(:opt1).must_equal(true)
            c.fetch(:k3).has_flag_option?(:opt1).must_equal(true)
            c.fetch(:k4).has_flag_option?(:opt2).must_equal(true)
            d = get_attr(:d)
            d.fetch(:k1).has_flag_option?(:opt2).must_equal(true)
            d.fetch(:k2).has_flag_option?(:opt2).must_equal(true)
            d.fetch(:k3).has_flag_option?(:opt2).must_equal(true)
            d.fetch(:k4).has_flag_option?(:opt1).must_equal(true)
          end
        end
      end

      # validates that default is a hash
      #
      check_fail "'a' attribute default must be a hash not a 'Array'", line: [__FILE__, 'tagU'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol do
              default [] # tagU
            end
          end
        end
      end

      # It validates default is a hash when block form is used
      #
      check_fail "'t.a' hash attribute default requires a hash not a 'Integer'", line: [__FILE__, 'tagO'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol do # tagO
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
      check_fail "'a' attribute default failed validation: 'not a symbol' must be a symbol but was a 'String'", line: [__FILE__, 'tagL'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol, type: :symbol do
              default({k: 'not a symbol'}) # tagL
            end
          end
        end
      end

      # It validates default elements respect attribute type when block form used
      #
      check_fail "'t.a' attribute failed validation: 'not a symbol' must be a symbol but was a 'String'", line: [__FILE__, 'tagW'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol, type: :symbol do # tagW
              default do
                {k: 'not a symbol'}
              end
            end
          end
          test :t # need an intance of test in order for block style defaults to be called
        end
      end
    end

    it 'checks for accessing uninitialised attributes' do
      # test with hash attr default using an unset attr
      #
      check_fail "Cannot read uninitialised 't.b' attribute", line: [__FILE__, 'tagI'] do
        jaba(barebones: true) do
          define :test do
            attr :a
            attr :b
            attr_hash :c, key_type: :symbol do
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
      check_fail "Cannot read uninitialised 't.a' hash attribute", line: [__FILE__, 'tagF'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol
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
          attr_hash :a, key_type: :symbol
          attr :b, type: :choice do
            items [1, 2]
          end
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

          # Value can be set in block
          #
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
          b 2
          a :key do
            case b
            when 1
              :yes
            else
              :no
            end
          end
          a[:key].must_equal :no
        end
      end
    end

    it 'is not possible to modify returned hash' do
      check_fail 'Cannot modify read only value', line: [__FILE__, 'tagN'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol do
              default({k: :v})
            end
          end
          test :t do
            a[:k] = :v2 # tagN
          end
        end
      end
    end

    it 'disallows :no_sort' do
      check_fail "'a' attribute failed validation: ':no_sort' flag is incompatible: :no_sort is only allowed on array attributes",
                line: [__FILE__, 'tagQ'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol do # tagQ
              flags :no_sort
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
            attr_hash :a, key_type: :symbol do # tagP
              flags :allow_dupes
            end
          end
        end
      end
    end
    
    it 'can accept flag options' do
      jaba(barebones: true) do
        define :test do
          attr_hash :a, key_type: :symbol do
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
          attr_hash :a, key_type: :symbol do
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
          attr_hash :a, key_type: :symbol do
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

    it 'validates key value supplied correctly' do
      check_fail("'t.a' hash attribute requires a key/value eg \"a :my_key, 'my value'\"", line: [__FILE__, 'tagM']) do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol
          end
          test :t do
            a key: 'val' # tagM
          end
        end
      end
      check_fail("'t.a' hash attribute requires a key/value eg \"a :my_key, 'my value'\"", line: [__FILE__, 'tagZ']) do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol
          end
          test :t do
            a :key # tagZ
          end
        end
      end
    end

    # TODO: test wipe
    
  end

end
