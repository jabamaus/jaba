module JABA

class TestAttributeDefinition < JabaTest

  describe 'AttributeDefinition' do
    
    it 'requires attribute id to be a symbol' do
      assert_raises DefinitionError do
        jaba do
          extend :project do
            attr 'attr' do
            end
          end
        end
      end.message.must_match('\'attr\' attribute id must be specified as a symbol')
    end
    
    it 'detects duplicate attribute ids' do
      assert_raises DefinitionError do
        jaba do
          extend :project do
            attr :a do
            end
            attr :a do
            end
          end
        end
      end.message.must_match("'a' attribute multiply defined")
    end
    
  end
  
end

end
