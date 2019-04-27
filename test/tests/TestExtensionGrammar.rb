module JABA

class TestExtensionGrammar < JabaTestCase

  describe 'ExtensionGrammar' do

    it 'supports adding an attribute to core types' do
      jaba do
        extend_project do
          attr :a do
          end
        end
        
        project :p do
          a 'val'
        end
      end
    end

    it 'supports definining new attribute flags' do
      jaba do
        attr_flag :Foo
        attr_flag :Bar
      end
      Foo.must_equal(AllowDupes << 1)
      Bar.must_equal(Foo << 1)
    end
    
  end
  
end

end
