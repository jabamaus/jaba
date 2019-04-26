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

  end
  
end

end
