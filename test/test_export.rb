jtest "only allows 'export' on array and hash properties" do
  jdl do
    attr :a, variant: :array do
      flags :exportable
    end
    attr :b, variant: :hash do
      flags :exportable
    end
    attr :c do
      JTest.assert_jaba_error "Error at #{JTest.src_loc("F3F376AD")}: 'c' attribute invalid - ':exportable' flag only allowed on array/hash attributes." do
        flags :exportable # F3F376AD
      end
    end
  end
  jaba do end
end

jtest "supports exporting attributes to dependents" do
  td = temp_dir
  make_file("app/main.cpp")
  make_file("lib/main.cpp")
  jdl(level: :full) do
    attr "target/uuid", variant: :array, type: :uuid do
      flags :per_target, :exportable
    end
  end
  op = jaba do
    target :app1, root: "#{td}/app" do
      type :console
      deps [:lib, :virtual_lib]
      vcglobal :BoolAttr, true
      src ["main.cpp"]
      define ["F", "A"]
    end
    target :app2, root: "#{td}/app" do
      type :console
      deps [:lib, :virtual_lib]
      vcglobal :BoolAttr, true
      src ["main.cpp"]
      define ["F", "A"]
    end
    target :lib, root: "#{td}/lib" do
      type :lib
      src ["main.cpp"]
      vcglobal :StringAttr, "s"
      vcglobal :StringAttr2, "s2", :export_only # will be sent to dependents but won't be defined on self
      vcglobal :StringAttr3, "s3", :export
      # TODO: what happens if export :BoolAttr, false ? will it overwrite? Probably fail. Warn if same value.
      define ["C", "B"], :export_only
      case config
      when :Debug
        define ["D"], :export
      when :Release
        define ["R"], :export
      end
      define "D2", :export if config == :Debug
      define "R2", :export if config == :Release
      define ["E"]
      inc ["include"], :force, :export
      uuid "uuid", :export
    end
    # virtual libs do not get created but all their attrs are automatically exported
    target :virtual_lib, root: "#{td}/lib", virtual: true do
      type :lib
      vcglobal :StringAttr4, "sd"
      case config
      when :Debug
        define ["VD"]
        syslibs ["debug.lib"]
      when :Release
        define ["VR"]
        syslibs ["release.lib"]
      end
    end
  end

  app1 = op[:root].get_child(:app1)
  app1[:vcglobal][:BoolAttr].must_equal "true"
  app1[:vcglobal][:StringAttr2].must_equal "s2"
  app1[:vcglobal][:StringAttr3].must_equal "s3"
  app1[:vcglobal][:StringAttr4].must_equal "sd"
  app1[:uuid].must_equal ["{6D82CA6D-E690-5E45-975F-1F54D32A755A}"]
  app1d = app1.get_child(:Debug)
  app1d[:define].must_equal ["A", "B", "C", "D", "D2", "F", "VD"]
  app1d.get_attr(:define).visit_elem do |elem|
    elem.has_flag_option?(:export).must_be_false
    elem.has_flag_option?(:export_only).must_be_false
  end
  app1d[:inc].must_equal ["#{temp_dir}/lib/include"]
  app1d[:syslibs].must_equal ["debug.lib"]
  app1r = app1.get_child(:Release)
  app1r[:define].must_equal ["A", "B", "C", "F", "R", "R2", "VR"]
  app1r[:inc].must_equal ["#{temp_dir}/lib/include"]
  app1r[:syslibs].must_equal ["release.lib"]

  app2 = op[:root].get_child(:app2)
  app2[:vcglobal][:BoolAttr].must_equal "true"
  app2[:vcglobal][:StringAttr2].must_equal "s2"
  app2[:vcglobal][:StringAttr3].must_equal "s3"
  app2[:vcglobal][:StringAttr4].must_equal "sd"
  app2[:uuid].must_equal ["{6D82CA6D-E690-5E45-975F-1F54D32A755A}"]
  app2d = app2.get_child(:Debug)
  app2d[:define].must_equal ["A", "B", "C", "D", "D2", "F", "VD"]
  app2d[:inc].must_equal ["#{temp_dir}/lib/include"]
  app2d[:syslibs].must_equal ["debug.lib"]
  app2r = app2.get_child(:Release)
  app2r[:define].must_equal ["A", "B", "C", "F", "R", "R2", "VR"]
  app2r[:inc].must_equal ["#{temp_dir}/lib/include"]
  app2r[:syslibs].must_equal ["release.lib"]

  lib = op[:root].get_child(:lib)
  lib[:vcglobal][:StringAttr].must_equal "s"
  lib[:vcglobal].has_key?(:StringAttr2).must_be_false # due to :export_only
  lib[:vcglobal][:StringAttr3].must_equal("s3")
  lib[:uuid].must_equal ["{6D82CA6D-E690-5E45-975F-1F54D32A755A}"]
  libd = lib.get_child(:Debug)
  libd[:define].must_equal ["D", "D2", "E"]
  libr = lib.get_child(:Release)
  libr[:define].must_equal ["E", "R", "R2"]
end

jtest "virtual targets warn if non-exportable attrs used" do
  jdl(level: :full) do
    attr "target/a", variant: :array, type: :int do
      flags :allow_dupes, :per_target
    end
  end
  op = jaba do
    target :app do
      deps :virtual_lib
    end
    target :virtual_lib, virtual: true do
      type :lib
      a 1 # B9C7088C
    end
  end
  op[:warnings].must_equal ["Warning at #{src_loc("B9C7088C")}: Non-exportable 'a' attribute ignored."]
end

jtest "virtual targets do not gain defaults" do
  jdl(level: :full) do
    attr "target/per_target", variant: :array, type: :int do
      flags :allow_dupes, :exportable, :per_target
    end
    attr "target/per_config", variant: :array, type: :int do
      flags :allow_dupes, :exportable, :per_target
    end
  end
  op = jaba do
    # virtual targets don't inherit contents of defaults block but they do inerhit
    # the options passed in.
    defaults scope: :global, configs: [:d, :r, :p] do
      per_target 1
      per_config 4
    end
    target :app do
      per_target 2
      per_config 5
      deps :virtual_lib
    end
    target :virtual_lib, virtual: true do
      type :lib
      per_target 3
      per_config 6
    end
  end
  t = op[:root].get_child(:app)
  t[:per_target].must_equal [1, 2, 3] # if virtual_lib had defaults applied there would be an additional 1
  d = t.get_child(:d)
  d[:per_config].must_equal [4, 5, 6]
  r = t.get_child(:d)
  r[:per_config].must_equal [4, 5, 6]
  p = t.get_child(:d)
  p[:per_config].must_equal [4, 5, 6]
end
