module JABA

class TestExtensionGrammar < JabaTest

  describe 'ExtensionGrammar' do

    it 'fails if try to extend undefined type' do
      e = assert_raises DefinitionError do
        jaba do
          extend :undefined do
          end
        end
      end
      e.message.must_match('\'undefined\' has not been defined')
      e.definition_type.must_equal(:undefined)
      e.definition_id.must_be_nil
    end
    
    it 'supports adding an attribute to core types' do
      jaba do
        extend :project do
          attr :a do
          end
        end
        
        project :p do
          a 'val'
          a.must_equal('val')
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

end
