module JABA

class TestBoolAttribute < JabaTest

  it 'defaults to false' do
    jaba do
      define :test do
        attr :a do
          type :bool
        end
      end
      test :t do
        a.must_equal(false)
      end
    end
  end

  it 'requires a default of true or false' do
    check_fails(':bool attributes only accept [true|false]',
                backtrace: [
                  [CoreTypesFile, "raise ':bool attributes only accept [true|false]'"],
                  [__FILE__, 'attr :b do'] # evaluated later so exact call line is lost
                ]) do
      jaba do
        define :test do
          attr :b do
            type :bool
            default 1
          end
        end
      end
    end
  end

  it 'only allows boolean values' do
    check_fails(':bool attributes only accept [true|false]',
                backtrace: [
                  [CoreTypesFile, "raise ':bool attributes only accept [true|false]'"],
                  [__FILE__, 'c 1']
                ]) do
      jaba do
        define :test do
          attr :c do
            type :bool
            default true
          end
        end
        test :b do
          c 1
        end
      end
    end
  end

  it 'supports boolean accessor when reading' do
    jaba do
      define :test do
        attr :d do
          type :bool
          default true
        end
      end
      test :b do
        d.must_equal(true)
        d?.must_equal(true)
        d false
        d.must_equal(false)
        d?.must_equal(false)
      end
    end
  end
  
  it 'rejects boolean accessor on non-boolean properties' do
    check_fails("'e' attribute is not of type :bool", backtrace: [[__FILE__, 'if e?']]) do
      jaba do
        define :test do
          attr :e do
            type :file
          end
        end
        test :a do
          if e?
          end
        end
      end
    end
  end
  
  it 'rejects passing array to non-array property' do
    check_fails("'f' attribute cannot accept an array as not flagged with :array", backtrace: [[__FILE__, 'f [true, false]']]) do
      jaba do
        define :test do
          attr :f do
            type :bool
          end
        end
        test :t do
          f [true, false]
        end
      end
    end
  end
  
end

end
