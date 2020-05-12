# frozen_string_literal: true

module JABA

  class TestCpp < JabaTest

    it 'is evaluated per-type, per-sku and per-config' do
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
      # TODO: use error 'help' to link to attribute definition      
      check_fail "'platforms' attribute requires a value", trace: [__FILE__, 'tagY'] do
        jaba do
          cpp :app do # tagY
          end
        end
      end
    end

    it 'prevents nil access' do
      op = jaba(dry_run: true) do
        cpp :app do
          platforms [:win32, :x64]
          projname "app_#{platform&.upcase}_#{host&.upcase}" # TODO: remove safe call
          hosts [:vs2017]
          if win32?
            configs [:debug]
          else
            configs [:release]
          end
        end
      end
      proj = op[:cpp]['cpp|app|win32|vs2017']
      proj.wont_be_nil
      proj[:projname].must_equal('app_WIN32_VS2017')
      proj[:configs][:debug].wont_be_nil
      proj[:configs][:release].must_be_nil
    end
=begin
    it 'supports exporting array attributes to dependents' do
      op = jaba(dry_run: true) do
        defaults :cpp do
          platforms [:x64]
          hosts [:vs2017]
          configs [:debug, :release]
        end
        cpp :app do
          deps :lib
          defines ['F', 'A']
        end
        cpp :lib do
          defines ['D']
          defines ['C', 'B'], :export
          defines ['R'], :export if config == :release
          defines ['E']
        end
      end
      app = op[:cpp]['cpp|app|x64|vs2017']
      app.wont_be_nil
      cfg_debug = app[:configs][:debug]
      cfg_debug.wont_be_nil
      cfg_debug[:defines].must_equal ['A', 'B', 'C', 'F']
      cfg_release = app[:configs][:release]
      cfg_release.wont_be_nil
      cfg_release[:defines].must_equal ['A', 'B', 'C', 'F', 'R']
    end
=end
  end

end

