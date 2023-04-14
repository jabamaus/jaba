jtest "project" do
  op = jaba do
    project :myapp do
      type :console
      case config
      when :Debug
        define "DEBUG"
      when :Release
        define "RELEASE"
      end
    end
  end
  r = op[:root]
  r[:configs].must_equal [:Debug, :Release]
  a = r.children[0]
  a.id.must_equal :myapp
  a.children.size.must_equal 2
  debug_conf = a.children[0]
  debug_conf[:define].must_equal ["DEBUG"]
  release_conf = a.children[1]
  release_conf[:define].must_equal ["RELEASE"]
end
