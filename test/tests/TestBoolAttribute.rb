module JABA

class TestBoolAttribute < JabaTest

  it 'defaults to false' do
    jaba do
      extend :text do
        attr :a do
          type :bool
        end
      end
      text :t do
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
        extend :text do
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
        extend :text do
          attr :c do
            type :bool
            default true
          end
        end
        text :b do
          c 1
        end
      end
    end
  end

  it 'supports boolean accessor when reading' do
    jaba do
      extend :text do
        attr :d do
          type :bool
          default true
        end
      end
      text :b do
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
        extend :text do
          attr :e do
            type :file
          end
        end
        text :a do
          if e?
          end
        end
      end
    end
  end
  
end

end
