module JABA

class TestKeyValueAttribute < JabaTest

  it 'defaults to empty hash' do
    jaba do
      define :test do
        attr :a, type: :keyvalue do
        end
      end
      test :t do
        a.must_equal({})
      end
    end
  end
  
  it 'can have a default' do
    jaba do
      define :test do
        attr :a, type: :keyvalue do
          default({k: :v})
        end
      end
      test :t do
        a[:k].must_equal(:v)
      end
    end
  end
  
  it 'can be set' do
    jaba do
      define :test do
        attr :a, type: :keyvalue do
        end
      end
      test :t do
        a :k, :v
        a[:k].must_equal(:v)
      end
    end
  end
  
  it 'works with array' do
    jaba do
      define :test do
        attr_array :a, type: :keyvalue do
        end
      end
      test :t do
        a :k1, :v1
        a :k2, :v2
        a :k3, :v3
        a.must_equal([{k1: :v1}, {k2: :v2}, {k3: :v3}])
      end
    end
  end
  
end

end
