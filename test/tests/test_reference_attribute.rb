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
    
    # Referencing a node of a different type automatically adds a dependency so that instances of the referenced
    # type are created first.
    #
    it 'resolves references to different types immediately' do
      jaba do
        define :type_a do
          attr :type_b, type: :reference do
            referenced_type :type_b
          end
        end
        define :type_b do
          attr :c do
            default 1
          end
        end
        type_a :a do
          type_b :b
          c.must_equal 1
        end
        type_b :b do
        end
      end
    end
    
    # TODO: test references with same id different types
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
    
    # TODO: test read only
    it 'automatically imports referenced node attributes read only' do
      jaba do
        define :test do
          attr :platform, type: :reference do
            referenced_type :platform
          end
          attr :host, type: :reference do
            referenced_type :host
          end
        end
        test :t do
          platform :win32
          host :vs2013
          platform.must_equal(:win32)
          host.must_equal(:vs2013)
          win32?.must_equal(true)
          windows?.must_equal(true)
          x64?.must_equal(false)
          iOS?.must_equal(false)
          macOS?.must_equal(false)
          apple?.must_equal(false)
          visual_studio?.must_equal(true)
          vs2013?.must_equal(true)
          vs2015?.must_equal(false)
          vs2017?.must_equal(false)
          vs2019?.must_equal(false)
          xcode?.must_equal(false)
        end
      end
    end
    
  end
  
end
