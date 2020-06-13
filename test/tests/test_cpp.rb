# frozen_string_literal: true

module JABA

  class TestCpp < JabaTest

    # TODO
    it 'is evaluated per-type, per-sku and per-config' do
      jaba do
      end
    end

    it 'supports defaults' do
      op = jaba(dry_run: true, dump_output: true) do
        defaults :cpp do
          hosts [:vs2019]
          platforms [:windows]
          archs [:x86]
          configs [:debug, :release]
          rtti false
        end
        cpp :app do
          type :app
          src ['main.cpp'], :force
          if config == :debug
            rtti true
          end
        end
      end
      proj = op[:cpp]['app|vs2019|windows']
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
      proj = jaba(dry_run: true, cpp_app: true) do
        cpp :app do
          projname "app_#{host&.upcase}" # TODO: remove safe call
          src ['main.cpp'], :force
        end
      end
      proj[:projname].must_equal('app_VS2019')
    end

    # TODO. Test that can control whether multiple platforms can be combined into one project or not
    # but how to test this as don't have acceess to any appropriate platforms
    it 'has a flexible approach to platforms' do
      jaba(dry_run: true, cpp_app: true) do
        cpp :app do
          src ['main.cpp'], :force
        end
      end
    end

    # TODO: test exporting references
    it 'supports exporting array attributes to dependents' do
      proj = jaba(dry_run: true, cpp_app: true) do
        cpp :app do
          deps [:lib]
          vcglobal :BoolAttr, true
          defines ['F', 'A']
          src ['main.cpp'], :force
        end
        cpp :lib do
          type :lib
          src ['main.cpp'], :force
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
      proj[:vcglobal][:BoolAttr].must_equal(true)
      proj[:vcglobal][:StringAttr2].must_equal('s2')
      proj[:vcglobal][:StringAttr3].must_equal('s3')
      cfg_debug = proj[:configs][:Debug]
      cfg_debug.wont_be_nil
      cfg_debug[:defines].must_equal ['A', 'B', 'C', 'F']
      cfg_release = proj[:configs][:Release]
      cfg_release.wont_be_nil
      cfg_release[:defines].must_equal ['A', 'B', 'C', 'F', 'R']
    end

    it 'only allows :export on array and hash properties' do
      # TODO
    end

    it 'supports opening translators' do
      proj = jaba(dry_run: true, cpp_app: true) do
        cpp :app do
          src ['main.cpp'], :force
        end
        open_translator :vcxproj_windows do
          vcglobal :NewGlobal, 'g'
        end
        open_translator :vcxproj_config_windows do
          vcproperty :NewProperty, 'p', group: :pg1
        end
      end
      proj[:vcglobal][:NewGlobal].must_equal('g')
      proj[:configs][:Debug][:vcproperty][:NewProperty].must_equal('p')
      proj[:configs][:Release][:vcproperty][:NewProperty].must_equal('p')
    end

  end

end

