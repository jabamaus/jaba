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
          configs [:debug, :release]
        end
        cpp :a do
          platforms [:x64]
        end
      end
      op[:cpp]['cpp|a|x64|vs2017'].wont_be_nil
    end

    it 'supports vcproperty' do
      
    end

    it 'reports errors correctly with subtype attributes' do
      check_fail "'platforms' attribute requires a value",
                trace: [__FILE__, 'tagY', CPP_DEFINITION_FILE, 'attr_array :platforms'] do
        jaba do
          cpp :app do # tagY
          end
        end
      end
    end

  end

end

