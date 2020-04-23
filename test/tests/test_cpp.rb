# frozen_string_literal: true

module JABA

  class TestCpp < JabaTest

    it 'is evaluated per-type, per-sku and per-target' do
      jaba do
      end
    end

    it 'supports defaults' do
      op = jaba do
        defaults :cpp do
          hosts [:vs2017]
        end
        cpp :a do
          platforms [:x64]
        end
      end
      op[:cpp]['cpp|a|x64|vs2017'].wont_be_nil
    end

  end

end
