module JABA

class TestGlobalDefinition < JabaTestCase

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
    
    it 'detects duplicate ids with definitions of the same type' do
      assert_raises DefinitionError do
        jaba do
          shared :a do
          end
          target :a do
          end
        end
      end.message.must_match('\'a\' multiply defined')
      assert_raises DefinitionError do
        jaba do
          project :b do
          end
          project :b do
          end
        end
      end.message.must_match('\'b\' multiply defined')
      e = assert_raises DefinitionError do
        jaba do
          category :c do
          end
          category :c do
          end
        end
      end
      e.message.must_match('\'c\' multiply defined')
    end
=begin
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
        attr :a do
        end
      end
    end
=end
  end
  
end

end
