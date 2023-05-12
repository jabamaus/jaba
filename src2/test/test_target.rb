jtest "target" do
  op = jaba do
    target :myapp do
      type :console
      configs [:debug, :release]
      case config
      when :debug
        define "DEBUG"
      when "release" # string should work too
        define "RELEASE"
      end
    end
  end
  r = op[:root].children[0] # app root node
  r.id.must_equal :myapp
  r.children.size.must_equal 1
  t = r.children[0] # target node
  t.children.size.must_equal 2 
  debug_conf = t.children[0]
  debug_conf[:define].must_equal ["DEBUG"]
  release_conf = t.children[1]
  release_conf[:define].must_equal ["RELEASE"]
end
