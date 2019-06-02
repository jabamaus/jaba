# frozen_string_literal: true

module JABA

  class TestProject < JabaTest

    it 'is evaluated per-type, per-sku and per-target' do
      jaba do
        project :p do
          platforms [:win32]
          targets [:a, :b]
          generate do
          end
        end
      end
    end
    
  end

end
