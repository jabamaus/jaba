# frozen_string_literal: true

module JABA

  class TestKeyValueAttribute < JabaTest

    it 'defaults to empty nil key value' do
      jaba do
        define :test do
          attr :a, type: :keyvalue
        end
        test :t do
          a.key.must_be_nil
          a.value.must_be_nil
        end
      end
    end
    
    it 'can have a default' do
      jaba do
        define :test do
          attr :a, type: :keyvalue do
            default KeyValue.new(:k, :v)
          end
        end
        test :t do
          a.key.must_equal :k
          a.value.must_equal :v
        end
      end
    end
    
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
          #b[0].key.must_equal(:a)
          #b[0].value.must_equal(:b)
          #b[1].key.must_equal(:c)
          #b[1].value.must_equal(:d)
        end
      end
    end
    
  end

end
