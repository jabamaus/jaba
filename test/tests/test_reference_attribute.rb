# frozen_string_literal: true

module JABA

  class TestReferenceAttribute < JabaTest
    
    it 'resolves references' do
      jaba do
        define :a do
          attr :b, type: :reference do
          end
          attr_array :c, type: :reference do
          end
        end
        define :d do
          attr :e do
          end
        end
        d :d1 do
          e 1
        end
        d :d2 do
          e 2
        end
        d :d3 do
          e 3
        end
        a :a_id do
          b :d1
          c [:d2, :d3]
          generate do
            b.e.must_equal 1
            c.size.must_equal 2
            c[0].e.must_equal 2
            c[1].e.must_equal 3
          end
        end
      end
    end
    
  end
  
end
