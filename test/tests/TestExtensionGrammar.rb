module JABA

class TestExtensionGrammar < JabaTest

  describe 'ExtensionGrammar' do

    it 'fails if try to extend undefined type' do
      check_fails(msg: "'undefined' has not been defined", file: __FILE__, line: 'extend :undefined') do
        jaba do
          extend :undefined do
          end
        end
      end
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

    it 'supports defining new attribute types' do
      check_fails(msg: 'Failed validation', file: __FILE__, line: "raise 'Failed validation'") do
        jaba do
          attr_type :a do
            validate do
              raise 'Failed validation'
            end
          end
          extend :text do
            attr :b do
              type :a
            end
          end
        end
      end
    end
    
    it 'detects usage of undefined attribute types' do
      e = assert_raises DefinitionError do
        jaba do
          define :a do
            attr :b do
              type :undefined
            end
          end
        end
      end
      e.message.must_match(/'undefined' attribute type is undefined. Valid types: \[.*?\]/)
      #e.file.must_equal(__FILE__)
      #e.line.must_equal(find_line_number('attr :undefined', __FILE__))
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
