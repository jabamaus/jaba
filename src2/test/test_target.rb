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
