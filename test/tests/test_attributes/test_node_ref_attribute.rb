# frozen_string_literal: true

module JABA

  class TestNodeRefAttribute < JabaTest
    
    it 'requires referent type to be specified' do
      check_fail "'b' attribute invalid: 'jaba_type' must be set", line: [__FILE__, 'tagP'] do
        jaba(barebones: true) do
          type :a do
            attr :b, type: :node_ref # tagP
          end
        end
      end
    end
    
    # Referencing a node of a different type automatically adds a dependency so that instances of the referenced
    # type are created first.
    #
    it 'resolves references to different types immediately' do
      jaba(barebones: true) do
        type :type_a do
          attr :type_b, type: :node_ref, jaba_type: :type_b
        end
        type :type_b do
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
    
    it 'strips duplicates' do
      line = find_line_number(__FILE__, 'tagL')
      check_warn("Stripping duplicate ':b' from 'a.ref' array attribute. See previous at test_node_ref_attribute.rb:#{line}", __FILE__, 'tagM') do
        jaba(barebones: true) do
          type :type_a do
            attr_array :ref, type: :node_ref, jaba_type: :type_b
          end
          type :type_b
          type_a :a do
            ref :b # tagL
            ref :b # tagM
            ref.size.must_equal(1)
          end
          type_b :b
        end
      end
    end

    it 'catches invalid reference to different type' do
      # TODO: don't like this error message
      check_fail 'Node with handle \'undefined\' not found', line: [__FILE__, 'tagW'] do
        jaba(barebones: true) do
          type :type_a do
            attr :ref, type: :node_ref, jaba_type: :type_b
          end
          type :type_b
          type_a :a do
            ref :undefined # tagW
          end
        end
      end
    end

    it 'resolves references to same type later' do
      jaba(barebones: true) do
        type :type_a do
          attr :ref, type: :node_ref, jaba_type: :type_a
          attr_array :ref_array, type: :node_ref, jaba_type: :type_a
        end
        type_a :a1 do
          ref :a3
          ref.must_equal :a3
          ref_array [:a2, :a3]
          generate do
            attrs.ref.defn_id.must_equal(:a3)
            attrs.ref_array[0].defn_id.must_equal(:a2)
            attrs.ref_array[1].defn_id.must_equal(:a3)
          end
        end
        type_a :a2 do
          ref :a1
          ref.must_equal :a1
          generate do
            attrs.ref.defn_id.must_equal(:a1)
          end
        end
        type_a :a3 do
        end
      end
    end
    
    it 'catches invalid reference to same type' do
      check_fail 'Node with handle \'undefined\' not found', line: [__FILE__, 'tagQ'] do
        jaba(barebones: true) do
          type :a do
            attr :b, type: :node_ref, jaba_type: :a
          end
          a :t do
            b :undefined # tagQ
          end
        end
      end
    end

    it 'works with a default' do
      jaba do
        type :type_a do
          attr :host, type: :node_ref, jaba_type: :host do
            default :vs2019
          end
        end
        type_a :a1 do
          host.version_year.must_equal 2019
        end
      end
    end
    
    it 'works with :required flag' do
    end
    
    it 'imports exposed referenced attributes' do
      check_fail "'height' attribute not found. The following attributes are available in this context:\n\n  Read/write:\n    square\n\n  Read only:\n    length\n\n.", line: [__FILE__, 'tagI'] do
        jaba(barebones: true) do
          type :square do
            attr :length do
              flags :expose
            end
            attr :height
          end
          square :a do
            length 1
            height 2
          end
          type :has_square do
            attr :square, type: :node_ref, jaba_type: :square
          end
          has_square :t do
            square :a
            length.must_equal(1)
            square.height.must_equal(2)

            # height has not been flagged with :expose, so should raise an error when used unqualified
            height # tagI
          end
        end
      end
    end

    it 'treats references read only when imported' do
      check_fail "Cannot change referenced 'length' attribute", line: [__FILE__, 'tagF'] do
        jaba(barebones: true) do
          type :line do
            attr :length do
              flags :expose
            end
          end
          line :a do
            length 1
          end
          type :references_line do
            attr :line, type: :node_ref, jaba_type: :line
          end
          references_line :t do
            line :a
            length 3 # tagF
          end
        end
      end
    end
    
    it 'treats references read only when called through object' do
      check_fail "'a.length' attribute is read only", line: [__FILE__, 'tagD'] do
        jaba(barebones: true) do
          type :line do
            attr :length
          end
          line :a do
            length 1
          end
          type :has_line do
            attr :line, type: :node_ref, jaba_type: :line
          end
          has_line :t do
            line :a
            line.length 3 # tagD
          end
        end
      end
    end

    it 'warns on unnecessary use of :read_only flag' do
      check_warn 'Object reference attribute does not need to be flagged with :read_only as they always are', __FILE__, 'tagX' do
        jaba do
          type :test do
            attr :platform, type: :node_ref, jaba_type: :platform do
              flags :read_only # tagX
            end
          end
        end
      end
    end

    it 'catches attribute name clashes' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagC)}: 'a' attribute multiply imported into 'test'. See previous at #{src_loc(__FILE__, :tagY)}." do
        jaba(barebones: true) do
          type :ref1 do
            attr :a do # tagY
              flags :expose
            end
          end
          type :ref2 do
            attr :a do # tagC
              flags :expose
            end
          end
          type :test do
            attr :r1, type: :node_ref, jaba_type: :ref1
            attr :r2, type: :node_ref, jaba_type: :ref2
          end
          test :t
        end
      end
    end

    # TODO: test referencing a node in a tree, using make_handle
  end
end
