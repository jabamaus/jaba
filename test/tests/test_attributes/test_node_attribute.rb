# frozen_string_literal: true

module JABA

  class TestNodeAttribute < JabaTest

    # TODO: test with default blocks
    # TODO: test with references
    # TODO: test if block not provided
    # TODO: test disallowing referencing self
    # TODO: test works with :required
    # TODO: test works with :export
    # TODO: what about sorting? Disable?

    it 'works with all attribute variants' do
      jaba do
        type :test do
          attr :node_single, type: :node do
            node_type :node
          end
          attr_array :node_array, type: :node do
            node_type :node
          end
          attr_hash :node_hash, key_type: :symbol, type: :node do
            node_type :node
          end
          attr :platform, type: :node_ref do
            node_type :platform
          end
        end
        type :node do
          attr :a
          attr_array :b
          attr_hash :c, key_type: :symbol
          attr :d, type: :node do
            node_type :node2
          end
        end
        type :node2 do
          attr :e, type: :node do
            node_type :node3
          end
        end
        type :node3 do
          attr :f
        end
        test :t do
          platform :windows
          node_single do
            a 'a'
            b ['c', 'd']
            if windows?
              c :e, 'f'
            end
            if ios?
              b ['e']
            end
            d do
              e do
                f 1
              end
            end
          end
          node_single.a.must_equal('a')
          node_single.b.must_equal ['c', 'd']
          node_single.c.must_equal({e: 'f'})
          node_single.d.e.f.must_equal(1)

          # Repeating overwrites/appends
          node_single do
            a 'a1'
            b ['c1', 'd1']
            if windows?
              c :e1, 'f1'
            end
            if ios?
              b ['e1']
            end
            d do
              e do
                f 2
              end
            end
          end
          node_single.a.must_equal('a1')
          node_single.b.must_equal ['c', 'd', 'c1', 'd1']
          node_single.c.must_equal({e: 'f', e1: 'f1'})
          node_single.d.e.f.must_equal(2)

          node_array do
            a 'a'
            b ['c', 'd']
            c :e, 'f'
          end
          node_array do
            a 'a1'
            b ['c1', 'd1']
            c :e1, 'f1'
          end
          node_array[0].a.must_equal('a')
          node_array[0].b.must_equal ['c', 'd']
          node_array[0].c.must_equal({e: 'f'})
          node_array[1].a.must_equal('a1')
          node_array[1].b.must_equal ['c1', 'd1']
          node_array[1].c.must_equal({e1: 'f1'})

          node_hash :k1 do |key|
            key.must_equal(:k1)
            a 'a'
            b ['c', 'd']
            c :e, 'f'
          end
          node_hash :k2 do
            a 'a1'
            b ['c1', 'd1']
            c :e1, 'f1'
          end
          node_hash[:k1].a.must_equal('a')
          node_hash[:k1].b.must_equal ['c', 'd']
          node_hash[:k1].c.must_equal({e: 'f'})
          node_hash[:k2].a.must_equal('a1')
          node_hash[:k2].b.must_equal ['c1', 'd1']
          node_hash[:k2].c.must_equal({e1: 'f1'})
        end
      end
    end
  end

end
