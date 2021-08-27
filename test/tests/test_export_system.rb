# frozen_string_literal: true

module JABA

  using JABACoreExt
  
  class TestExportSystem < JabaTest

    # TODO: test exporting references
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagQ)}: :exportable attribute definition flag is only allowed on array and hash attributes.",
                        trace: [__FILE__, :tagW] do
        jaba(dry_run: true) do
          type :test do
            attr :a do # tagW
              flags :exportable # tagQ
            end
          end
        end
      end
    end

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
          # TODO: test paths with root
          root "#{td}/lib"
          src ['lib.cpp'], :force # test exporting an attribute that belongs to project
          inc 'lib.h'
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
      app[:configs][:x86][:Debug][:inc].must_equal ['lib/lib.h']
      app[:configs][:x86][:Debug][:syslibs].must_equal ['libdebug_x86.lib']
      app[:configs][:x86][:Release][:define].must_equal ['R']
      app[:configs][:x86][:Release][:syslibs].must_equal ['librelease_x86.lib']
      app[:configs][:x86_64][:Debug][:define].must_equal ['D']
      app[:configs][:x86_64][:Debug][:syslibs].must_equal ['libdebug_x64.lib']
      app[:configs][:x86_64][:Release][:define].must_equal ['R']
      app[:configs][:x86_64][:Release][:syslibs].must_equal ['librelease_x64.lib']
      op[:cpp]['lib|vs2019|windows'].must_be_nil
    end

  end

end
