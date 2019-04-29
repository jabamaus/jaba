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
        attr_flag :foo
        attr_flag :bar
        
        extend_project do
          attr :a do
            flags :foo, :bar
          end
        end
      end
      # TODO: test something
    end
    
  end
  
end

end
