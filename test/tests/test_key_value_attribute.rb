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
    
    it 'sorts unless :unordered specified' do
      jaba do
        define :test do
          attr_array :a, type: :keyvalue
          attr_array :b, type: :keyvalue do
            flags :unordered
          end
        end
        test :t do
          a :x, :a
          a :q, :b
          a :b, :c
          a :m, :o
          generate do
            attrs.a.size.must_equal 4
            attrs.a[0].key.must_equal :b
            attrs.a[0].value.must_equal :c
            attrs.a[1].key.must_equal :m
            attrs.a[1].value.must_equal :o
            attrs.a[2].key.must_equal :q
            attrs.a[2].value.must_equal :b
            attrs.a[3].key.must_equal :x
            attrs.a[3].value.must_equal :a
           end
        end
      end
    end
    
    it 'strips duplicates unless :allow_dupes specified' do
       jaba do
         define :test do
           attr_array :a, type: :keyvalue do
             flags :unordered
           end
           attr_array :b, type: :keyvalue do
             flags :allow_dupes, :unordered
           end
         end
         test :t do
           a :k, :v
           a :k, :v
           a :k, :v
           a :k2, :v
           a :k, :v2
           b :k, :v
           b :k, :v
           b :k, :v
           generate do
             attrs.a.size.must_equal 3
             attrs.a[0].key.must_equal :k
             attrs.a[0].value.must_equal :v
             attrs.a[1].key.must_equal :k2
             attrs.a[1].value.must_equal :v
             attrs.a[2].key.must_equal :k
             attrs.a[2].value.must_equal :v2
             attrs.b.size.must_equal 3
             attrs.b[0].key.must_equal :k
             attrs.b[0].value.must_equal :v
             attrs.b[1].key.must_equal :k
             attrs.b[1].value.must_equal :v
             attrs.b[2].key.must_equal :k
             attrs.b[2].value.must_equal :v
           end
         end
       end
    end
    
  end

end
