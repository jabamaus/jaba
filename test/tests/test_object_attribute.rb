# frozen_string_literal: true

module JABA

  class TestObjectAttribute < JabaTest

    it 'works with single attribute' do
      jaba(barebones: true) do
        define :test do
          attr :obj, type: :object do
            object_type :obj
          end
        end
        define :obj do
          attr :a
          attr_array :b
          attr_hash :c, key_type: :symbol
        end
        test :t do
=begin
          obj do
            a 'a'
            b ['c', 'd']
            c :e, 'f'
          end
          obj.a.must_equal('a')
          obj.b.must_equal ['c', 'd']
          obj.c.must_equal({e: 'f'})
=end
        end
      end
    end

  end

end
