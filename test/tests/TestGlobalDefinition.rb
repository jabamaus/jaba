module JABA

class TestGlobalDefinition < JabaTestCase

  describe 'GlobalDefinition' do
  
    it 'requires a id' do
      e = assert_raises DefinitionError do
        jaba do
          shared do
          end
        end
      end
      e.message.must_match("'shared' must have an id")
      e.file.wont_be_nil
      e.line.wont_be_nil
      e.definition_id.must_be_nil
      e.definition_type.must_equal(:shared)
    end
    
  end
  
end

end
