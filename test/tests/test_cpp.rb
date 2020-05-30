# frozen_string_literal: true

module JABA

  class TestCpp < JabaTest

    # TODO
    it 'is evaluated per-type, per-sku and per-config' do
      jaba do
      end
    end

    it 'supports defaults' do
      op = jaba(dry_run: true) do
        defaults :cpp do
          hosts [:vs2017]
          platforms [:windows]
          archs [:x86]
          configs [:debug, :release]
          rtti false
        end
        cpp :a do
          type :app
          if config == :debug
            rtti true
          end
        end
      end

      proj = op[:cpp]['cpp|a|vs2017|windows']
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

    # TODO: test different approaches to root/projroot
    it 'supports vcproperty' do
      
    end

    it 'reports errors correctly with subtype attributes' do
      check_fail "'hosts' attribute requires a value", trace: [__FILE__, 'tagY'] do
        jaba do
          cpp :app do # tagY
          end
        end
      end
    end

    it 'prevents nil access when attributes not set up yet' do
      op = jaba(dry_run: true, cpp_app: true) do
        cpp :app do
          projname "app_#{host&.upcase}" # TODO: remove safe call
        end
      end
      proj = op[:cpp]['cpp|app|vs2017|windows']
      proj.wont_be_nil
      proj[:projname].must_equal('app_VS2017')
    end

    # TODO. Test that can control whether multiple platforms can be combined into one project or not
    # but how to test this as don't have acceess to any appropriate platforms
    it 'has a flexible approach to platforms' do
      jaba(dry_run: true, cpp_app: true) do
        cpp :app do

        end
      end
    end

    it 'supports exporting array attributes to dependents' do
      op = jaba(dry_run: true, cpp_app: true) do
        cpp :app do
          deps [:lib]
          vcglobal :BoolAttr, true
          defines ['F', 'A']
        end
        cpp :lib do
          type :lib
          vcglobal :StringAttr, 's'
          vcglobal :StringAttr2, 's2', :export
          vcglobal :StringAttr3, 's3', :export
          # TODO: what happens if export :BoolAttr, false ? will it overwrite? Probably fail. Warn if same value.
          defines ['D']
          defines ['C', 'B'], :export
          defines ['R'], :export if config == :Release
          defines ['E']
          # TODO: test vcproperty
        end
      end
      app = op[:cpp]['cpp|app|vs2017|windows']
      app.wont_be_nil
      app[:vcglobal][:BoolAttr].must_equal(true)
      app[:vcglobal][:StringAttr2].must_equal('s2')
      app[:vcglobal][:StringAttr3].must_equal('s3')
      cfg_debug = app[:configs][:Debug]
      cfg_debug.wont_be_nil
      cfg_debug[:defines].must_equal ['A', 'B', 'C', 'F']
      cfg_release = app[:configs][:Release]
      cfg_release.wont_be_nil
      cfg_release[:defines].must_equal ['A', 'B', 'C', 'F', 'R']
    end

    it 'only allows :export on array and hash properties' do
      # TODO
    end

  end

end

