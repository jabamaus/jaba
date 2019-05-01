module JABA

class TestAttributeDefinition < JabaTest

  describe 'AttributeDefinition' do
    
    it 'requires attribute id to be a symbol' do
      e = assert_raises DefinitionError do
        jaba do
          extend :project do
            attr 'attr' do
            end
          end
        end
      end
      e.message.must_match('\'attr\' attribute id must be specified as a symbol')
      e.definition_type.must_equal(:project)
      e.definition_id.must_be_nil
    end
    
    it 'detects duplicate attribute ids' do
      e = assert_raises DefinitionError do
        jaba do
          extend :project do
            attr :a do
            end
            attr :a do
            end
          end
        end
      end
      e.message.must_match("'a' attribute multiply defined")
      e.definition_type.must_equal(:project)
      e.definition_id.must_be_nil
    end
    
  end
  
end

end
