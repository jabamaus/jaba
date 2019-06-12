# frozen_string_literal: true

module JABA

  class TestReferenceAttribute < JabaTest
    
    it 'requires referent type to be specified' do
      check_fail "'b' attribute definition failed validation: 'referenced_type' must be set",
                 trace: [CORE_TYPES_FILE, "raise \"'referenced_type' must be set\"", __FILE__, '# tag1'] do
        jaba do
          define :a do
            attr :b, type: :reference # tag1
          end
        end
      end
    end
    
    it 'validates reference' do
      check_fail 'Node with handle \'undefined\' not found', trace: [__FILE__, '# tag2'] do
        jaba do
          define :a do
            attr :b, type: :reference do
              referenced_type :a
            end
          end
          a :t do
            b :undefined # tag2
          end
        end
      end
    end
    
    it 'resolves references to dependent types immediately' do
      jaba do
        define :type_a do
          dependencies :host
          attr :host_ref, type: :reference do
            referenced_type :host
          end
        end
        type_a :a do
          host_ref :vs2017
          host_ref.id.must_equal(:vs2017)
          host_ref.visual_studio.must_equal(true)
        end
      end
    end
    
    it 'resolves references' do
      jaba do
        define :a do
          dependencies :d
          attr :b, type: :reference do
            referenced_type :d
          end
          attr_array :c, type: :reference do
            referenced_type :d
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
