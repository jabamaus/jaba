module JABA

class TestGlobalDefinition < JabaTest

  describe 'GlobalDefinition' do
  
    it 'rejects invalid ids' do
      jaba do
        shared :Alpha_Num3r1cs_With_Underscores_Are_Valid_Everything_Else_Is_Not do
        end
        shared 'Str1ngs_also_allowed' do
        end
        shared 'this.is.valid' do
        end
      end
      e = assert_raises DefinitionError do
        jaba do
          shared 'Space invalid' do
          end
        end
      end
      e.message.must_match("'Space invalid' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'")
      e.definition_type.must_equal(:shared)
      e.definition_id.must_equal('Space invalid')
      
      e = assert_raises DefinitionError do
        jaba do
          shared 1 do
          end
        end
      end
      e.message.must_match(/'1' is an invalid id/)
      e.definition_type.must_equal(:shared)
      e.definition_id.must_equal(1)
    end
    
    it 'detects duplicate ids with definitions of the same type' do
      e = assert_raises DefinitionError do
        jaba do
          shared :a do
          end
          shared :a do
          end
        end
      end
      e.message.must_match('\'a\' multiply defined')
      e.definition_type.must_equal(:shared)
      e.definition_id.must_equal(:a)

      e = assert_raises DefinitionError do
        jaba do
          project :b do
          end
          project :b do
          end
        end
      end
      e.message.must_match('\'b\' multiply defined')
      e.definition_type.must_equal(:project)
      e.definition_id.must_equal(:b)
      
      e = assert_raises DefinitionError do
        jaba do
          category :c do
          end
          category :c do
          end
        end
      end
      e.message.must_match('\'c\' multiply defined')
      e.definition_type.must_equal(:category)
      e.definition_id.must_equal(:c)
    end

    it 'allows different types to have the same id' do
      jaba do
        shared :a do
        end
        project :a do
        end
        target :a do
        end
        workspace :a do
        end
      end
    end

  end
  
end

end
