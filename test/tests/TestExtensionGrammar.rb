module JABA

class TestExtensionGrammar < JabaTestCase

  describe 'ExtensionGrammar' do
=begin
    it 'supports defining a new attribute type' do
      jaba do
        attr_type :version do
        end
        
        attr :version do
          type :version
        end
        
        project :a do
          version '1.0'
        end
      end
    end
    
    it 'supports adding an attribute to core objects by value' do
      jaba do
        project do
          attr :a do
          end
        end
        
        project :p do
          a 'val'
        end
      end
    end

    it 'supports adding an attribute to core objects by reference' do
      jaba do
        attr :a do
        end
        
        #project do
        #  attr :a
        #end
        
        project :p do
          a 'val'
        end
      end
    end
=end
  end
  
end

end
