# frozen_string_literal: true

module JABA

  class TestReferenceAttribute < JabaTest
    
    it 'requires referent type to be specified' do
      check_fail "'b' attribute definition failed validation: 'referenced_type' must be set",
                 trace: [ATTR_DEFINITION_FILE, "fail \"'referenced_type' must be set\"", __FILE__, 'tagP'] do
        jaba do
          define :a do
            attr :b, type: :reference # tagP
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
          attr :d do
            default 2
            flags :expose
          end
        end
        type_a :a do
          type_b :b
          type_b.c.must_equal 1
          d.must_equal 2
        end
        type_b :b do
        end
      end
    end
    
    it 'catches invalid reference to different type' do
      check_fail 'Node with handle \'type_b|undefined\' not found', trace: [__FILE__, 'tagW'] do
        jaba do
          define :type_a do
            attr :ref, type: :reference do
              referenced_type :type_b
            end
          end
          define :type_b
          type_a :a do
            ref :undefined # tagW
          end
        end
      end
    end

    it 'resolves references to same type later' do
      jaba do
        define :type_a do
          attr :ref, type: :reference do
            referenced_type :type_a
          end
          attr_array :ref_array, type: :reference do
            referenced_type :type_a
          end
        end
        type_a :a1 do
          ref :a3
          ref.must_equal :a3
          ref_array [:a2, :a3]
          generate do
            attrs.ref.definition_id.must_equal(:a3)
            attrs.ref_array[0].definition_id.must_equal(:a2)
            attrs.ref_array[1].definition_id.must_equal(:a3)
          end
        end
        type_a :a2 do
          ref :a1
          ref.must_equal :a1
          generate do
            attrs.ref.definition_id.must_equal(:a1)
          end
        end
        type_a :a3 do
        end
      end
    end
    
    it 'catches invalid reference to same type' do
      check_fail 'Node with handle \'a|undefined\' not found', trace: [__FILE__, 'tagQ'] do
        jaba do
          define :a do
            attr :b, type: :reference do
              referenced_type :a
            end
          end
          a :t do
            b :undefined # tagQ
          end
        end
      end
    end

    it 'works with a default' do
      jaba do
        define :type_a do
          attr :host, type: :reference do
            referenced_type :host
            default :vs2017
          end
        end
        type_a :a1 do
          host.version_year.must_equal 2017
        end
      end
    end
    
    it 'works with :required flag' do
    end
    
    it 'imports exposed referenced attributes' do
      check_fail "'vsname' attribute not defined", trace: [__FILE__, 'tagI'] do
        jaba do
          define :test do
            attr :platform, type: :reference do
              referenced_type :platform
            end
          end
          test :t do
            platform :win32
            win32?.must_equal(true)
            x64?.must_equal(false)
            windows?.must_equal(true)
            apple?.must_equal(false)

            # vsname is defined in platform but has not been flagged with :expose, so should raise an error
            vsname # tagI
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
          # TODO
          #platform._ID.must_equal(:win32)
          #host._ID.must_equal(:vs2013)
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
    
    # TODO: test attribute name clashes
  end
  
end
