module JABA

class TestExtensionGrammar < JabaTest

  it 'supports creating new object types' do
    jaba do
      define :test do
        attr :a do
        end
      end
      test :t do
        a 'b'
        a.must_equal('b')
      end
    end
  end

  it 'fails if try to extend undefined type' do
    check_fails("'undefined' has not been defined", backtrace: [[__FILE__, 'extend :undefined']]) do
      jaba do
        extend :undefined do
        end
      end
    end
  end
  
  it 'supports adding an attribute to core types' do
    jaba do
      extend :project do
        attr :a do
        end
      end
      
      project :p do
        skus [:win32_vs2017]
        targets [:t]
        a 'val'
        a.must_equal('val')
      end
    end
  end

  # TODO: extend
  it 'supports defining new attribute types' do
    check_fails("'b' attribute failed validation: Invalid", backtrace: [[__FILE__, "raise 'invalid'"], [__FILE__, "b 'c'"]]) do 
      jaba do
        attr_type :a do
          validate_value do |val|
            raise 'invalid'
          end
        end
        define :test do
          attr :b do
            type :a
          end
        end
        test :t do
          b 'c'
        end
      end
    end
  end
  
  it 'detects usage of undefined attribute types' do
    check_fails(/'undefined' attribute type is undefined. Valid types: \[.*?\]/, backtrace: [[__FILE__, 'type :undefined']]) do
      jaba do
        define :a do
          attr :b do
            type :undefined
          end
        end
      end
    end
  end
  
  it 'supports definining new attribute flags' do
    jaba do
      attr_flag :foo
      attr_flag :bar
      
      extend :project do
        attr :a do
          flags :foo, :bar
        end
      end
    end
    # TODO: test something
  end
  
end

end
