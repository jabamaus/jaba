# frozen_string_literal: true

module JABA

  class TestCpp < JabaTest

    it 'is evaluated per-type, per-sku and per-target' do
      jaba do
      end
    end

    it 'supports defaults' do
      op = jaba(dry_run: true) do
        defaults :cpp do
          platforms [:x64]
          hosts [:vs2017]
          configs [:debug, :release]
          rtti false
        end
        cpp :a do
          if config == :debug
            rtti true
          end
        end
      end

      proj = op[:cpp]['cpp|a|x64|vs2017']
      proj.wont_be_nil

      cfg_debug = proj[:configs][:debug]
      cfg_debug.wont_be_nil
      cfg_debug[:rtti].wont_be_nil
      cfg_debug[:rtti].must_equal(true)

      cfg_release = proj[:configs][:release]
      cfg_release.wont_be_nil
      cfg_release[:rtti].wont_be_nil
      cfg_release[:rtti].must_equal(false)
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

