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
    target :myapp do
      type :console
      if debug?
        define "DEBUG"
      else
        define "RELEASE"
      end
    end
  end
  root = op[:root]
  root.children.size.must_equal 1
  myapp = root.get_child(:myapp) # app root node
  myapp.sibling_id.must_equal :myapp
  myapp.children.size.must_equal 1
  t = myapp.children[0] # target node
  t.children.size.must_equal 2
  debug_conf = t.children[0]
  debug_conf[:configname].must_equal "Debug"
  debug_conf[:define].must_equal ["DEBUG"]
  release_conf = t.children[1]
  release_conf[:configname].must_equal "Release"
  release_conf[:define].must_equal ["RELEASE"]
end

jtest "supports optional per target and per config blocks" do
  assert_output 'tcc' do
    jaba do
      target :myapp do
        per_target do
          print 't'
        end
        per_config do
          print 'c'
        end
      end
    end
  end
end

jtest "supports default block" do
  op = jaba do
    extend_jdl do
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
    defaults scope: :global, myopt1: 1, myopt2: 2, array: [1] do
      projname "My#{id}"
    end
    defaults scope: :file, myopt2: 3, array: [2, 3] do # myopt2 overrides global default, array will append
      if debug?
        define 'D'
      else
        define 'R'
      end
    end
    target :app1, array: [4, 5] do
    end
    target :app2, myopt1: 4 do
    end
  end
  root = op[:root]
  app1 = root.get_child(:app1)
  t = app1.children[0]
  t[:projname].must_equal "Myapp1"
  t[:myopt1].must_equal 1
  t[:myopt2].must_equal 3
  t[:array].must_equal [1, 2, 3, 4, 5]
  debug_conf = t.children[0]
  debug_conf[:define].must_equal ["D"]
  debug_conf[:config].must_equal "Debug"
  rel_conf = t.children[1]
  rel_conf[:config].must_equal "Release"
  rel_conf[:define].must_equal ["R"]

  app2 = root.get_child(:app2)
  t = app2.children[0]
  t[:projname].must_equal "Myapp2"
  t[:myopt1].must_equal 4
  t[:myopt2].must_equal 3
  t[:array].must_equal [1, 2, 3]
  debug_conf = t.children[0]
  debug_conf[:define].must_equal ["D"]
  debug_conf[:config].must_equal "Debug"
  rel_conf = t.children[1]
  rel_conf[:config].must_equal "Release"
  rel_conf[:define].must_equal ["R"]
end