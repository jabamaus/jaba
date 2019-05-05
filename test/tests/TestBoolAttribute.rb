module JABA

class TestBoolAttribute < JabaTest

  describe 'BoolAttribute' do
    
    it 'defaults to false' do
      jaba do
        extend :text do
          attr :enabled do
            type :bool
          end
        end
        text :t do
          enabled.must_equal(false)
        end
      end
    end
    
    it 'requires a default of true or false' do
      e = assert_raises DefinitionError do
        jaba do
          extend :text do
            attr :enabled do
              type :bool
              default 1
            end
          end
        end
      end
      #e.message.must_match('\'enabled\' attribute has invalid default')
      #e.file.must_equal(__FILE__)
      #e.line.must_equal(find_line_number('default 1', __FILE__))
      #e.definition_type.must_equal(:text)
      #e.definition_id.must_be_nil
    end
    
    it 'supports boolean accessor when reading' do
      jaba do
        extend :text do
          attr :enabled do
            type :bool
            default true
          end
        end
        text :b do
          enabled.must_equal(true)
          enabled?.must_equal(true)
          enabled false
          enabled.must_equal(false)
          enabled?.must_equal(false)
        end
      end
    end
    
    it 'rejects boolean accessor on non-boolean properties' do
    end
    
  end
  
end

end
