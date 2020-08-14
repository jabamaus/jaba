# frozen_string_literal: true

module JABA

  class TestNodeAttribute < JabaTest

    # TODO: test with default blocks
    # TODO: test with references
    # TODO: test if block not provided
    # TODO: test disallowing referencing self

    it 'works with single attribute' do
      jaba(barebones: true) do
        define :test do
          attr :obj, type: :node do
            node_type :obj
          end
        end
        define :obj do
          attr :a
          attr_array :b
          attr_hash :c, key_type: :symbol
          attr :d, type: :node do
            node_type :obj2
          end
        end
        define :obj2 do
          attr :e
        end

        test :t do
          obj do
            a 'a'
            b ['c', 'd']
            c :e, 'f'
            d do
              e 1
            end
          end
          obj.a.must_equal('a')
          obj.b.must_equal ['c', 'd']
          obj.c.must_equal({e: 'f'})
          #obj.d.e.must_equal(1)
        end
      end
    end

    it 'works with array attribute' do
      jaba(barebones: true) do
        define :test do
          attr_array :obj, type: :node do
            node_type :obj
          end
        end
        define :obj do
          attr :a
          attr_array :b
          attr_hash :c, key_type: :symbol
        end
        test :t do
          obj do
            a 'a'
            b ['c', 'd']
            c :e, 'f'
          end
          obj do
            a 'a1'
            b ['c1', 'd1']
            c :e1, 'f1'
          end
          obj[0].a.must_equal('a')
          obj[0].b.must_equal ['c', 'd']
          obj[0].c.must_equal({e: 'f'})
          obj[1].a.must_equal('a1')
          obj[1].b.must_equal ['c1', 'd1']
          obj[1].c.must_equal({e1: 'f1'})
        end
      end
    end

  end

end
