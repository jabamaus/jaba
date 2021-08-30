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
          project do
            configs [:debug, :release]
          end
          config do
            rtti false
          end
        end
        cpp :app do
          platforms [:windows_x86, :windows_x86_64]
          project do
            type :app
            src ['main.cpp'], :force
          end
          config do
            if config == :debug
              rtti true
            end
          end
        end
      end
      proj = op[:cpp]['app|windows']
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
              project do
                type :console
                configs [:Release]
                src ['main.cpp'], :force
              end
              config do
                vcprop key, 'val' # tagJ
              end
            end
          end
        end
      end
    end

    # TODO: not much of a test....
    it 'prevents nil access when attributes not set up yet' do
      proj = jaba(dry_run: true, cpp_app: true) do
        cpp :app do
          project do
            projname "app_#{host.id.upcase}"
            src ['main.cpp'], :force
          end
        end
      end
      proj[:projname].must_equal('app_VS2019')
    end

    # TODO. Test that can control whether multiple platforms can be combined into one project or not
    # but how to test this as don't have acceess to any appropriate platforms
    it 'has a flexible approach to platforms' do
      jaba(dry_run: true, cpp_app: true) do
        cpp :app do
          project do
            src ['main.cpp'], :force
          end
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
            platforms [:windows_x86]
            project do
              type :console
              configs [:Debug, :Release]
              deps [:lib] # tagG
              src ['main.cpp']
            end
          end
        end
      end
    end

    it 'supports opening translators' do
      proj = jaba(dry_run: true, cpp_app: true) do
        cpp :app do
          project do
            src ['main.cpp'], :force
          end
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

  end

end
