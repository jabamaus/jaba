module JABA

class TestBoolAttribute < JabaTest

  it 'defaults to false' do
    jaba do
      define :test do
        attr :a, type: :bool do
        end
      end
      test :t do
        a.must_equal(false)
      end
    end
  end

  it 'requires a default of true or false' do
    check_fails(':bool attributes only accept [true|false]',
                trace: [
                  CoreTypesFile, "raise ':bool attributes only accept [true|false]'",
                  __FILE__, '# tag1' # evaluated later so exact call line is lost
                ]) do
      jaba do
        define :test do
          attr :b, type: :bool do # tag1
            default 1
          end
        end
      end
    end
  end

  it 'only allows boolean values' do
    check_fails(':bool attributes only accept [true|false]',
                trace: [
                  CoreTypesFile, "raise ':bool attributes only accept [true|false]'",
                  __FILE__, '# tag2'
                ]) do
      jaba do
        define :test do
          attr :c, type: :bool do
            default true
          end
        end
        test :b do
          c 1 # tag2
        end
      end
    end
  end

  it 'supports boolean accessor when reading' do
    jaba do
      define :test do
        attr :d, type: :bool do
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
    check_fails("'e' attribute is not of type :bool", trace: [__FILE__, '# tag3']) do
      jaba do
        define :test do
          attr :e, type: :file do
          end
        end
        test :a do
          if e? # tag3
          end
        end
      end
    end
  end
  
end

end
