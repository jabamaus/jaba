# frozen_string_literal: true

module JABA

  using JABACoreExt
  
  class TestCpp < JabaTest

    CPP_VS_JDL_FILE = "#{__dir__}/../../modules/cpp/VisualStudio/cpp_vs.jaba".cleanpath

    # TODO
    it 'is evaluated per-type, per-sku and per-config' do
      jaba do
      end
    end

    it 'supports defaults' do
      op = jaba(dry_run: true) do
        defaults :cpp do
          configs [:debug, :release]
          rtti false
        end
        cpp :app do
          type :app
          platforms [:windows_x86, :windows_x86_64]
          src ['main.cpp'], :force
          if config == :debug
            rtti true
          end
        end
      end
      proj = op[:cpp]['app|vs2019|windows']
      proj.wont_be_nil

      cfg_debug = proj[:configs][:x86][:debug]
      cfg_debug.wont_be_nil
      cfg_debug[:rtti].wont_be_nil
      cfg_debug[:rtti].must_equal(true)

      cfg_release = proj[:configs][:x86][:release]
      cfg_release.wont_be_nil
      cfg_release[:rtti].wont_be_nil
      cfg_release[:rtti].must_equal(false)
    end

    # TODO: test different approaches to root/projdir

    it 'supports vcprop' do
      # Test that keys always contain exactly 1 | character with something either side
      #
      invalid_keys = ['PG1_CharacterSet', '|PG1|CharacterSet', '|', 'A||B', 'win32/file.c|ObjectFileName']
      err_loc = src_loc(CPP_VS_JDL_FILE, '"Must be of form <group>|<property>')
      invalid_keys.each do |key|
        assert_jaba_error "Error at #{err_loc}: 'app.vcprop' hash attribute invalid: Must be of form <group>|<property> but was '#{key}'.", trace: [__FILE__, :tagJ] do
          jaba(dry_run: true) do
            cpp :app do
              platforms [:windows_x86_64] 
              configs [:Release]
              src ['main.cpp'], :force
              vcprop key, 'val' # tagJ
              type :console
            end
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

    it 'fails if dependency not found' do
      td = temp_dir
      make_file("app/main.cpp")
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagG)}: ':lib' dependency not found." do
        jaba do
          cpp :app do
            root "#{td}/app"
            type :console
            platforms [:windows_x86]
            configs [:Debug, :Release]
            deps [:lib] # tagG
            src ['main.cpp']
          end
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
          platforms [:windows_x86]
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
          vcglobal :StringAttr2, 's2', :export_only # will be sent to dependents but won't be defined on self
          vcglobal :StringAttr3, 's3', :export
          # TODO: what happens if export :BoolAttr, false ? will it overwrite? Probably fail. Warn if same value.
          define ['D']
          define ['C', 'B'], :export_only
          define ['R'], :export if config == :Release
          define ['E']
          inc ['include'], :export
          # TODO: test vcprop
        end
      end
      app = op[:cpp]['app|vs2019|windows']
      app[:vcglobal][:BoolAttr].must_equal(true)
      app[:vcglobal][:StringAttr2].must_equal('s2')
      app[:vcglobal][:StringAttr3].must_equal('s3')
      app[:configs][:x86][:Debug][:define].must_equal ['A', 'B', 'C', 'F']
      app[:configs][:x86][:Release][:define].must_equal ['A', 'B', 'C', 'F', 'R']
      app[:configs][:x86][:Debug][:inc].must_equal ['lib/include']
      app[:configs][:x86][:Release][:inc].must_equal ['lib/include']

      lib = op[:cpp]['lib|vs2019|windows']
      lib[:vcglobal][:StringAttr].must_equal('s')
      lib[:vcglobal].has_key?(:StringAttr2).must_equal(false)
      lib[:vcglobal][:StringAttr3].must_equal('s3')
      lib[:configs][:x86][:Debug][:define].must_equal ['D', 'E']
      lib[:configs][:x86][:Release][:define].must_equal ['D', 'E', 'R']
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
          vcprop 'PG1|NewProperty', 'p'
        end
      end
      proj[:vcglobal][:NewGlobal].must_equal('g')
      proj[:configs][:x86][:Debug][:vcprop]['PG1|NewProperty'].must_equal('p')
      proj[:configs][:x86][:Release][:vcprop]['PG1|NewProperty'].must_equal('p')
      proj[:configs][:x86_64][:Debug][:vcprop]['PG1|NewProperty'].must_equal('p')
      proj[:configs][:x86_64][:Release][:vcprop]['PG1|NewProperty'].must_equal('p')
    end
=begin
    it 'supports export only definitions' do
      td = temp_dir
      op = jaba(dry_run: true) do
        cpp :app do
          platforms [:windows_x86, :windows_x86_64]
          configs [:Debug, :Release]
          root td
          type :app
          src ['main.cpp'], :force
          deps :lib
        end
        cpp :lib, :export_only do
          src ['lib.cpp'], :force # test exporting an attribute that belongs to project
          if debug
            define 'D'
            if x86_64?
              syslibs 'libdebug_x64.lib'
            else
              syslibs 'libdebug_x86.lib'
            end
          else
            define 'R'
            if x86_64?
              syslibs 'librelease_x64.lib'
            else
              syslibs 'librelease_x86.lib'
            end
          end
        end
      end
      app = op[:cpp]['app|vs2019|windows']
      app.wont_be_nil
      app[:configs][:x86][:Debug][:define].must_equal ['D']
      app[:configs][:x86][:Debug][:syslibs].must_equal ['libdebug_x86.lib']
      app[:configs][:x86][:Release][:define].must_equal ['R']
      app[:configs][:x86][:Release][:syslibs].must_equal ['librelease_x86.lib']
      app[:configs][:x86_64][:Debug][:define].must_equal ['D']
      app[:configs][:x86_64][:Debug][:syslibs].must_equal ['libdebug_x86_64.lib']
      app[:configs][:x86_64][:Release][:define].must_equal ['R']
      app[:configs][:x86_64][:Release][:syslibs].must_equal ['librelease_x86_64.lib']
      op[:cpp]['lib|vs2019|windows'].must_be_nil
    end
=end
  end

end
