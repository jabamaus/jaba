# frozen_string_literal: true

module JABA

  class TestAttributeHash < JabaTest

    it 'defaults to empty hash' do
      jaba do
        define :test do
          attr_hash :a
        end
        test :t do
          a.must_equal({})
        end
      end
    end

    it 'can have a default' do
      jaba do
        define :test do
          attr_hash :a do
            default({k: :v})
          end
        end
        test :t do
          a[:k].must_equal(:v)
        end
      end
    end
=begin    
    it 'can be set' do
      jaba do
        define :test do
          attr :a, type: :keyvalue
        end
        test :t do
          # Test basic set
          a :k, :v
          a.key.must_equal(:k)
          a.value.must_equal(:v)
          
          # Overwrite value
          a :k, nil
          a.key.must_equal(:k)
          a.value.must_be_nil
          
          # Overwrite back to original
          a :k, :v
          a.key.must_equal(:k)
          a.value.must_equal(:v)
          
          # Change key. Old key/value is overwritten
          a :k2, :v2
          a.key.must_equal(:k2)
          a.value.must_equal(:v2)
        end
      end
    end
    
    it 'works with array' do
      jaba do
        define :test do
          attr_array :a, type: :keyvalue
          attr_array :b, type: :keyvalue do
            default [KeyValue.new(:a, :b), KeyValue.new(:c, :d)]
          end
        end
        test :t do
          a :k1, :v1
          a :k2, :v2
          a :k3, :v3
          a[0].key.must_equal(:k1)
          a[0].value.must_equal(:v1)
          a[1].key.must_equal(:k2)
          a[1].value.must_equal(:v2)
          a[2].key.must_equal(:k3)
          a[2].value.must_equal(:v3)
          # TODO: these are failing
          # b[0].key.must_equal(:a)
          # b[0].value.must_equal(:b)
          # b[1].key.must_equal(:c)
          # b[1].value.must_equal(:d)
        end
      end
    end
=end
    it 'sorts unless :unordered specified' do
    end
    
    it 'strips duplicates unless :allow_dupes specified' do
    end
    
    it 'can accept flag options' do
      jaba do
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

    it 'can accept keyval options' do
      jaba do
        define :test do
          attr_hash :a do
            keyval_options :kv1, :kv2
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

    it 'can accept keyval and flag options' do
      jaba do
        define :test do
          attr_hash :a do
            keyval_options :kv1, :kv2
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
      check_fail("Hash attribute requires a value", trace: [__FILE__, 'tagM']) do
        jaba do
          define :test do
            attr_hash :a
          end
          test :t do
            a :key # tagM
          end
        end
      end
    end

  end

end
