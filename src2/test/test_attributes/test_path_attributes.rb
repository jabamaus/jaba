jtest "checks path is valid" do
  jdl do
    attr "file", type: :file
    attr "dir", type: :dir
    attr "src_spec", type: :src
    attr "basename", type: :basename
  end
  op = jaba(want_exceptions: false) do
    file "a\\b" # 4E60BC17
    dir "a\\b" # F7B16193
    src_spec "a\\b" # CE17A7F3
    basename "a\\b" # CB2F8547
  end
  w = op[:warnings]
  w.size.must_equal 3
  w[0].must_equal "Warning at #{src_loc("4E60BC17")}: 'file' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[1].must_equal "Warning at #{src_loc("F7B16193")}: 'dir' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[2].must_equal "Warning at #{src_loc("CE17A7F3")}: 'src_spec' attribute not specified cleanly: 'a\\b' contains backslashes."
  op[:error].must_equal "Error at #{src_loc("CB2F8547")}: 'basename' attribute invalid - 'a\\b' must not contain slashes."
end
=begin
jtest "paths are made absolute" do
  JDL.node "node_7656F39C"
  JDL.attr "node_7656F39C|root"
  JDL.attr "node_7656F39C|file", type: :file
  JDL.attr "node_7656F39C|dir", type: :dir
  JDL.attr "node_7656F39C|src_spec", type: :src_spec
  JDL.attr "node_7656F39C|basename", type: :basename
  op = jaba do
    node_7656F39C :t1 do
      file "../a"
    end
    node_7656F39C :t2, root: "b" do
      file "../a"
    end
  end
  n = op[:root].children[0]
  n.root.must_equal __dir__
  n[:file].must_equal "#{__dir__.parent_path}/a"
end
=end
