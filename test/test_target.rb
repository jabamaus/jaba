=begin
jtest "fails if no src matched" do
  assert_jaba_error "Error at #{src_loc("FF78746B")}: 'app|windows' node does not have any source files." do
    jaba do
      target :app do # FF78746B
        src ["**/*.h"]
      end
    end
  end
end
=end
jtest "target" do
  op = jaba do
    target :app do
      type :console
      if debug?
        define "D"
      else
        define "R"
      end
    end
  end
  root = op[:root]
  root.children.size.must_equal 1
  app = root.get_child(:app)
  app.sibling_id.must_equal :app
  app.children.size.must_equal 2
  d = app.get_child(:debug)
  d[:configname].must_equal "Debug"
  d[:define].must_equal ["D"]
  r = app.get_child(:release)
  r[:configname].must_equal "Release"
  r[:define].must_equal ["R"]
end

jtest "supports default block" do
  jdl(level: :full) do
    attr "target/myopt1", type: :int do
      flags :node_option
    end
    attr "target/myopt2", type: :int do
      flags :node_option
    end
    attr "target/array", variant: :array, type: :int do
      flags :node_option
    end
  end
  op = jaba do
    defaults scope: :global, myopt1: 1, myopt2: 2, array: [1] do
      projname "My#{id}"
    end
    defaults scope: :file, myopt2: 3, array: [2, 3] do # myopt2 overrides global default, array will append
      define debug? ? 'D' : 'R'
    end
    target :app1, array: [4, 5]
    target :app2, myopt1: 4
  end
  root = op[:root]

  a1 = root.get_child(:app1)
  a1[:projname].must_equal "Myapp1"
  a1[:myopt1].must_equal 1
  a1[:myopt2].must_equal 3
  a1[:array].must_equal [1, 2, 3, 4, 5]
  d = a1.get_child(:debug)
  d[:define].must_equal ["D"]
  d[:config].must_equal "debug"
  r = a1.get_child(:release)
  r[:config].must_equal "release"
  r[:define].must_equal ["R"]

  a2 = root.get_child(:app2)
  a2[:projname].must_equal "Myapp2"
  a2[:myopt1].must_equal 4
  a2[:myopt2].must_equal 3
  a2[:array].must_equal [1, 2, 3]
  d = a2.get_child(:debug)
  d[:define].must_equal ["D"]
  d[:config].must_equal "debug"
  r = a2.get_child(:release)
  r[:config].must_equal "release"
  r[:define].must_equal ["R"]
end

jtest "it supports config mapping" do
  op = jaba do
    target :lib1, virtual: true, configs: [:debug, :release] do
      define configname
    end
    # jaba will auto match obvious matches
    target :app1, configs: [:app_debug, :app_release] do
      deps :lib1
    end
  end
  app = op[:root].get_child(:app1)
  d = app.get_child(:app_debug)
  d[:define].must_equal ['Debug']
  r = app.get_child(:app_release)
  r[:define].must_equal ['Release']
end

jtest "app target gets all static library dependencies" do
  op = jaba do
    target :lib1 do
      type :lib
    end
    target :lib2 do
      type :lib
      deps :lib1
    end
    target :lib3 do
      type :lib
      deps :lib2
    end
    target :app do
      deps :lib3
    end
  end
  app = op[:root].get_child(:app)
  app[:deps].map{|d| d.sibling_id}.must_equal [:lib3, :lib2, :lib1]
end

jtest "target supports override" do
  make_file("MyLibOveriddenRoot/main.cpp")
  op = jaba do
    target :lib, root: "#{JTest.temp_dir}MyLibRoot" do
      type :lib
      define 'A'
    end
    target :lib, root: "#{JTest.temp_dir}/MyLibOveriddenRoot", override: true do
      define 'B'
    end
    target :lib, override: true, virtual: true do
      define 'C'
    end
  end
  lib = op[:root].get_child(:lib)
  lib[:root].must_equal "#{temp_dir}/MyLibOveriddenRoot"
  d = lib.get_child(:debug)
  d[:define].must_equal ['A', 'B', 'C']
end
