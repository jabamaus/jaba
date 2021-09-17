class TestCompoundAttribute < JabaTest

  # TODO: test with default blocks
  # TODO: test with references
  # TODO: test if block not provided
  # TODO: test disallowing referencing self
  # TODO: test works with :required
  # TODO: test works with :export
  # TODO: what about sorting? Disable?

  # TODO: split on_set tests out
  it 'works with all attribute variants' do
    jaba do
      type :test do
        attr :node_single, type: :compound, jaba_type: :compound
        attr_array :node_array, type: :compound, jaba_type: :compound
        attr_hash :node_hash, key_type: :symbol, type: :compound, jaba_type: :compound
        attr :platform, type: :ref, jaba_type: :platform
        attr :sibling_single
        attr_array :sibling_array do
          flags :allow_dupes
        end
        attr_hash :sibling_hash, key_type: :symbol
      end
      type :compound do
        attr :a do
          # members of a compound attr can set values in 'sibling' attrs, which are actually in the parent node
          on_set do |val|
            sibling_single val * 2
            sibling_array val * 2
            sibling_hash val, val * 2
          end
        end
        attr_array :b
        attr_hash :c, key_type: :symbol
        attr :d, type: :compound, jaba_type: :nested1
      end
      type :nested1 do
        attr :e, type: :compound, jaba_type: :nested2
      end
      type :nested2 do
        attr :f
      end
      test :t do
        platform :windows
        node_single do
          a 1
          b [2, 3]
          if windows? # It can query attrs in parent node
            c 4, 5
          end
          if ios?
            b [6]
          end
          d do
            e do # they can be nested
              f 7
            end
          end
        end
        node_single.a.must_equal(1)
        node_single.b.must_equal [2, 3]
        node_single.c.must_equal({4 => 5})
        node_single.d.e.f.must_equal(7)
        sibling_single.must_equal(2)
        sibling_array.must_equal [2]
        sibling_hash.must_equal({1 => 2})

        # Repeating overwrites/appends
        node_single do
          a 8
          b [9, 10]
          if windows?
            c 11, 12
          end
          if ios?
            b [13]
          end
          d do
            e do
              f 14
            end
          end
        end
        node_single.a.must_equal(8)
        node_single.b.must_equal [2, 3, 9, 10]
        node_single.c.must_equal({4 => 5, 11 => 12})
        node_single.d.e.f.must_equal(14)
        sibling_single.must_equal(16)
        sibling_array.must_equal [2, 16]
        sibling_hash.must_equal({1 => 2, 8 => 16})

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
