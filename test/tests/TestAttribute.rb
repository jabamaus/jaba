module JABA

class TestAttribute < JabaTest

  it 'rejects passing array to single value attribute' do
    check_fails("'a' attribute cannot accept an array as not flagged with :array", backtrace: [[__FILE__, '# tag1']]) do
      jaba do
        define :test do
          attr :a do
          end
        end
        test :t do
          a [1, 2] # tag1
        end
      end
    end
  end
  
  # TODO: check wiping down required values
  it 'supports wiping value back to default' do
    jaba do
      define :test do
        attr :a do
          default 1
        end
        attr :b do
          default 'b'
        end
        attr :c do
          default :c
        end
        attr :d do
          default nil
        end
      end
      test :t do
        a.must_equal(1)
        a 2
        a.must_equal(2)
        b.must_equal('b')
        b 'bb'
        c.must_equal(:c)
        c :cc
        d.must_be_nil
        d 'd'
        d.must_equal('d')
        wipe :a
        wipe :b, :c, :d
        a.must_equal(1)
        b.must_equal('b')
        c.must_equal(:c)
        d.must_be_nil
      end
    end
  end
  
end

end
