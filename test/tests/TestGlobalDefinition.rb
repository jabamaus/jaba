module JABA

class TestGlobalDefinition < JabaTestCase

  describe 'GlobalDefinition' do
=begin
    it 'requires an id' do
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
=end
    it 'rejects invalid ids' do
      jaba do
        shared :Alpha_Num3r1cs_With_Underscores_Are_Valid_Everything_Else_Is_Not do
        end
        shared 'Str1ngs_also_allowed' do
        end
        shared 'this.is.valid' do
        end
      end
      assert_raises DefinitionError do
        jaba do
          shared 'Space invalid' do
          end
        end
      end.message.must_match("'Space invalid' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'")
      assert_raises DefinitionError do
        jaba do
          shared 1 do
          end
        end
      end.message.must_match(/'1' is an invalid id/)
    end
    
    it 'detects duplicate ids' do
      e = assert_raises DefinitionError do
        jaba do
          shared :a do
          end
          target :a do
          end
        end
      end
      e.file.wont_be_nil
      e.line.wont_be_nil
      e.message.must_match('\'a\' multiply defined')
    end
    
  end
  
end

end
