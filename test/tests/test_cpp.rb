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
          hosts [:vs2019], platforms: [:windows_x86]
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

    # TODO: test different approaches to root/projdir
    it 'supports vcproperty' do
      
    end

    it 'reports errors correctly with subtype attributes' do
      check_fail "'app.hosts' array attribute requires a value", line: [__FILE__, 'tagY'] do
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
    # Note that exported items are deleted from exported module by default
    #
    it 'supports exporting array attributes to dependents' do
      td = temp_dir
      make_file("app/main.cpp")
      make_file("lib/main.cpp")
      op = jaba do
        defaults :cpp do
          hosts [:vs2019], platforms: [:windows_x86, :windows_x86_64]
          configs [:Debug, :Release]
        end
        cpp :app do
          root "#{td}/app"
          type :console
          deps [:lib]
          vcglobal :BoolAttr, true
          define ['F', 'A']
          src ['main.cpp']
        end
        cpp :lib do
          root "#{td}/lib"
          type :lib
          src ['main.cpp']
          vcglobal :StringAttr, 's'
          vcglobal :StringAttr2, 's2', :export
          vcglobal :StringAttr3, 's3', :export, :no_delete
          # TODO: what happens if export :BoolAttr, false ? will it overwrite? Probably fail. Warn if same value.
          define ['D']
          define ['C', 'B'], :export
          define ['R'], :export if config == :Release
          define ['E']
          inc ['include'], :export
          # TODO: test vcproperty
        end
      end
      app = op[:cpp]['app|vs2019|windows']
      app[:vcglobal][:BoolAttr].must_equal(true)
      app[:vcglobal][:StringAttr2].must_equal('s2')
      app[:vcglobal][:StringAttr3].must_equal('s3')
      app[:configs][:Debug][:define].must_equal ['A', 'B', 'C', 'F']
      app[:configs][:Release][:define].must_equal ['A', 'B', 'C', 'F', 'R']
      app[:configs][:Debug][:inc].must_equal ['lib/include']
      app[:configs][:Release][:inc].must_equal ['lib/include']

      lib = op[:cpp]['lib|vs2019|windows']
      lib[:vcglobal][:StringAttr].must_equal('s')
      lib[:vcglobal].has_key?(:StringAttr2).must_equal(false)
      lib[:vcglobal][:StringAttr3].must_equal('s3')
      lib[:configs][:Debug][:define].must_equal ['D', 'E']
      lib[:configs][:Release][:define].must_equal ['D', 'E']
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
          vcproperty 'PG1|NewProperty', 'p'
        end
      end
      proj[:vcglobal][:NewGlobal].must_equal('g')
      proj[:configs][:Debug][:vcproperty]['PG1|NewProperty'].must_equal('p')
      proj[:configs][:Release][:vcproperty]['PG1|NewProperty'].must_equal('p')
    end

  end

end

