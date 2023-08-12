jtest "only allows 'export' on array and hash properties" do
  jdl do
    attr :a, variant: :array do
      flags :exportable
    end
    attr :b, variant: :hash do
      flags :exportable
    end
    attr :c do
      JTest.assert_jaba_error "Error at #{JTest.src_loc('F3F376AD')}: 'c' attribute invalid - ':exportable' flag only allowed on array/hash attributes." do
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
  op = jaba do
    target :app1, root: "#{td}/app" do
      type :console
      deps [:lib]
      vcglobal :BoolAttr, true
      src ['main.cpp']
      define ['F', 'A']
    end
    target :app2, root: "#{td}/app" do
      type :console
      deps [:lib]
      vcglobal :BoolAttr, true
      src ['main.cpp']
      define ['F', 'A']
    end
    target :lib, root: "#{td}/lib" do
      type :lib
      src ['main.cpp']
      vcglobal :StringAttr, 's'
      vcglobal :StringAttr2, 's2', :export_only # will be sent to dependents but won't be defined on self
      vcglobal :StringAttr3, 's3', :export
      # TODO: what happens if export :BoolAttr, false ? will it overwrite? Probably fail. Warn if same value.
      define ['C', 'B'], :export_only
      case config
      when :Debug
        define ['D'], :export
      when :Release
        define ['R'], :export
      end
      define 'D2', :export if config == :Debug
      define 'R2', :export if config == :Release
      define ['E']
      inc ['include'], :force, :export
    end
  end

  app1 = op[:root].get_child(:app1).children[0]
  app1[:vcglobal][:BoolAttr].must_equal "true"
  app1[:vcglobal][:StringAttr2].must_equal "s2"
  app1[:vcglobal][:StringAttr3].must_equal "s3"
  app1d = app1.get_child(:Debug)
  app1d[:define].must_equal ['A', 'B', 'C', 'D', 'D2', 'F']
  app1d.get_attr(:define).visit_elem do |elem|
    elem.has_flag_option?(:export).must_be_false
    elem.has_flag_option?(:export_only).must_be_false
  end
  app1d[:inc].must_equal ["#{temp_dir}/lib/include"]
  app1r = app1.get_child(:Release)
  app1r[:define].must_equal ['A', 'B', 'C', 'F', 'R', 'R2']
  app1r[:inc].must_equal ["#{temp_dir}/lib/include"]
=begin
  app2 = op[:cpp]['app2|windows']
  app2[:vcglobal][:BoolAttr].must_equal(true)
  app2[:vcglobal][:StringAttr2].must_equal('s2')
  app2[:vcglobal][:StringAttr3].must_equal('s3')
  app2[:configs][:x86][:Debug][:define].must_equal ['A', 'B', 'C', 'F']
  app2[:configs][:x86][:Release][:define].must_equal ['A', 'B', 'C', 'F', 'R']
  app2[:configs][:x86][:Debug][:inc].must_equal ["#{temp_dir}/lib/include"]
  app2[:configs][:x86][:Release][:inc].must_equal ["#{temp_dir}/lib/include"]

  lib = op[:cpp]['lib|windows']
  lib[:vcglobal][:StringAttr].must_equal('s')
  lib[:vcglobal].has_key?(:StringAttr2).must_equal(false)
  lib[:vcglobal][:StringAttr3].must_equal('s3')
  lib[:configs][:x86][:Debug][:define].must_equal ['D', 'E']
  lib[:configs][:x86][:Release][:define].must_equal ['D', 'E', 'R']
=end
end
