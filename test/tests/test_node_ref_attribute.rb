# frozen_string_literal: true

module JABA

  class TestNodeRefAttribute < JabaTest
    
    it 'requires referent type to be specified' do
      check_fail "'b' attribute invalid: 'node_type' must be set", line: [__FILE__, 'tagP'] do
        jaba(barebones: true) do
          define :a do
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
        define :type_a do
          attr :type_b, type: :node_ref do
            node_type :type_b
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
      # TODO: don't like this error message
      check_fail 'Node with handle \'undefined\' not found', line: [__FILE__, 'tagW'] do
        jaba(barebones: true) do
          define :type_a do
            attr :ref, type: :node_ref do
              node_type :type_b
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
      jaba(barebones: true) do
        define :type_a do
          attr :ref, type: :node_ref do
            node_type :type_a
          end
          attr_array :ref_array, type: :node_ref do
            node_type :type_a
          end
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
          define :a do
            attr :b, type: :node_ref do
              node_type :a
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
          attr :host, type: :node_ref do
            node_type :host
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
      check_fail "'height' attribute not defined", line: [__FILE__, 'tagI'] do
        jaba(barebones: true) do
          define :square do
            attr :length do
              flags :expose
            end
            attr :height
          end
          square :a do
            length 1
            height 2
          end
          define :has_square do
            attr :square, type: :node_ref do
              node_type :square
            end
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
          define :line do
            attr :length do
              flags :expose
            end
          end
          line :a do
            length 1
          end
          define :has_line do
            attr :line, type: :node_ref do
              node_type :line
            end
          end
          has_line :t do
            line :a
            length 3 # tagF
          end
        end
      end
    end
    
    it 'treats references read only when caled through object' do
      check_fail "'a.length' attribute is read only", line: [__FILE__, 'tagD'] do
        jaba(barebones: true) do
          define :line do
            attr :length
          end
          line :a do
            length 1
          end
          define :has_line do
            attr :line, type: :node_ref do
              node_type :line
            end
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
          define :test do
            attr :platform, type: :node_ref do # tagX
              node_type :platform
              flags :read_only
            end
          end
        end
      end
    end
    # TODO: test attribute name clashes

    # TODO: what about referencing sub types?

    # TODO: test referencing a node in a tree, using make_handle

    it 'prevents nil access when building tree of nodes' do
      jaba do
        define :testproj do
          attr_array :platforms
          define :platform do
            attr :platform, type: :node_ref do
              node_type :platform
            end
            attr_array :hosts
          end
          define :main do
            attr :host, type: :node_ref do
              node_type :host
            end
            attr :path
          end
        end

        testproj :t do
          platforms [:windows]
          hosts [:vs2019]
          path "#{platform.valid_archs[0]}/#{host.version_year}"
          generate do
            children[0].children[0].attrs.path.must_equal("x86/2019")
          end
        end
      end
    end
  end

  class TestprojGenerator < Generator
          
    def make_nodes
      platforms_node = make_node
      
      platforms_node.attrs.platforms.each do |p|
        hosts_node = make_node(sub_type_id: :platform, name: p, parent: platforms_node) do
          platform p
        end
        hosts_node.attrs.hosts.each do |h|
          make_node(sub_type_id: :main, name: h, parent: hosts_node) do 
            host h
          end
        end
      end
      platforms_node
    end
  end

end
