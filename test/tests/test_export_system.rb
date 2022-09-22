jtest "only allows 'export' on array and hash properties" do
  assert_jaba_error "Error at #{src_loc('F3F376AD')}: :exportable attribute definition flag is only allowed on array and hash attributes." do
    jaba(dry_run: true) do
      type :test do
        attr :a do
          flags :exportable # F3F376AD
        end
      end
    end
  end
  jaba(dry_run: true) do
    type :test do
      attr_array :a do
        flags :exportable
      end
      attr_hash :b, key_type: :string do
        flags :exportable
      end
    end
  end
end

# TODO: test exporting references
jtest 'supports exporting array attributes to dependents' do
  td = temp_dir
  make_file("app/main.cpp")
  make_file("lib/main.cpp")
  op = jaba do
    defaults :cpp do
      platforms [:windows_x86]
      project do
        configs [:Debug, :Release]
      end
    end
    cpp :app do
      root "#{td}/app"
      project do
        type :console
        deps [:lib]
        vcglobal :BoolAttr, true
        src ['main.cpp']
      end
      config do
        define ['F', 'A']
      end
    end
    cpp :lib do
      root "#{td}/lib"
      project do
        type :lib
        src ['main.cpp']
        vcglobal :StringAttr, 's'
        vcglobal :StringAttr2, 's2', :export_only # will be sent to dependents but won't be defined on self
        vcglobal :StringAttr3, 's3', :export
      end
      config do
        # TODO: what happens if export :BoolAttr, false ? will it overwrite? Probably fail. Warn if same value.
        define ['D']
        define ['C', 'B'], :export_only
        define ['R'], :export if config == :Release
        define ['E']
        inc ['include'], :export
        # TODO: test vcprop
      end
    end
  end
  app = op[:cpp]['app|windows']
  app[:vcglobal][:BoolAttr].must_equal(true)
  app[:vcglobal][:StringAttr2].must_equal('s2')
  app[:vcglobal][:StringAttr3].must_equal('s3')
  app[:configs][:x86][:Debug][:define].must_equal ['A', 'B', 'C', 'F']
  app[:configs][:x86][:Release][:define].must_equal ['A', 'B', 'C', 'F', 'R']
  app[:configs][:x86][:Debug][:inc].must_equal ["#{temp_dir}/lib/include"]
  app[:configs][:x86][:Release][:inc].must_equal ["#{temp_dir}/lib/include"]

  lib = op[:cpp]['lib|windows']
  lib[:vcglobal][:StringAttr].must_equal('s')
  lib[:vcglobal].has_key?(:StringAttr2).must_equal(false)
  lib[:vcglobal][:StringAttr3].must_equal('s3')
  lib[:configs][:x86][:Debug][:define].must_equal ['D', 'E']
  lib[:configs][:x86][:Release][:define].must_equal ['D', 'E', 'R']
end

# TODO: incorporate host query
jtest 'supports export only definitions' do
  td = temp_dir
  op = jaba(dry_run: true) do
    cpp :app do
      root td
      platforms [:windows_x86, :windows_x86_64]
      project do
        configs [:Debug, :Release]
        type :app
        src ['main.cpp'], :force
        deps :lib
      end
    end
    cpp :lib, :export_only do
      root "#{td}/lib"
      project do
        src ['lib.cpp'], :force # test exporting an attribute that belongs to project
      end
      config do
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
  end
  app = op[:cpp]['app|windows']
  app.wont_be_nil
  app[:configs][:x86][:Debug][:define].must_equal ['D']
  app[:configs][:x86][:Debug][:inc].must_equal ["#{temp_dir}/lib/lib.h"]
  app[:configs][:x86][:Debug][:syslibs].must_equal ['libdebug_x86.lib']
  app[:configs][:x86][:Release][:define].must_equal ['R']
  app[:configs][:x86][:Release][:inc].must_equal ["#{temp_dir}/lib/lib.h"]
  app[:configs][:x86][:Release][:syslibs].must_equal ['librelease_x86.lib']
  app[:configs][:x86_64][:Debug][:define].must_equal ['D']
  app[:configs][:x86_64][:Debug][:inc].must_equal ["#{temp_dir}/lib/lib.h"]
  app[:configs][:x86_64][:Debug][:syslibs].must_equal ['libdebug_x64.lib']
  app[:configs][:x86_64][:Release][:define].must_equal ['R']
  app[:configs][:x86_64][:Release][:inc].must_equal ["#{temp_dir}/lib/lib.h"]
  app[:configs][:x86_64][:Release][:syslibs].must_equal ['librelease_x64.lib']
  op[:cpp]['lib|windows'].must_be_nil

  # It fails if attribute not defined
  assert_jaba_error "Error at #{src_loc('FA730462')}: 'does_not_exist' attribute not found", ignore_rest: true do
    jaba(dry_run: true) do
      cpp :app do
        platforms [:windows_x86_64]
        project do
          configs [:Debug, :Release]
          type :app
          src ['main.cpp'], :force
          deps :lib
        end
      end
      cpp :lib, :export_only do
        project do
          does_not_exist 1 # FA730462
        end
      end
    end
  end
end

jtest 'only allows exportable attrs to be set in export only definitions' do
  td = temp_dir
  assert_jaba_warn "Ignoring 'lib.deps' array attribute as attribute definition not flagged with :exportable", __FILE__, '4E203E88' do
    jaba(dry_run: true, cpp_app: true) do
      cpp :app do
        project do
          src ['main.cpp'], :force
          deps :lib
        end
      end
      cpp :lib, :export_only do
        root "#{td}/lib"
        project do
          deps [:lib2] # 4E203E88
        end
      end
      cpp :lib2 do
        project do
          type :lib
          src ['main.cpp'], :force
        end
      end
    end
  end
end

# TODO: test that if export only module has specified valid platforms they are respected
