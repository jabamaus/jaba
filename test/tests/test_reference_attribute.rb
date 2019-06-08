# frozen_string_literal: true

module JABA

  class TestReferenceAttribute < JabaTest
    
    it 'resolves references' do
      jaba do
        define :a do
          attr :b, type: :reference do
          end
        end
        define :c do
          attr :d do
          end
        end
        c :c_id do
          d 1
        end
        a :a_id do
          b :c_id
          generate do
            b.d.must_equal 1
          end
        end
      end
    end
    
  end
  
end
