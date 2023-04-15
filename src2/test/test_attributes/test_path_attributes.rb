jtest "checks path is valid" do
  JDL.node "node_83D99E1E"
  JDL.attr "node_83D99E1E|file", type: :file
  JDL.attr "node_83D99E1E|dir", type: :dir
  JDL.attr "node_83D99E1E|src_spec", type: :src_spec
  JDL.attr "node_83D99E1E|basename", type: :basename
  op = jaba(want_exceptions: false) do
    node_83D99E1E :t do
      file "a\\b" # 4E60BC17
      dir "a\\b" # F7B16193
      src_spec "a\\b" # CE17A7F3
      basename "a\\b" # CB2F8547
    end
  end
  w = op[:warnings]
  w.size.must_equal 3
  w[0].must_equal "Warning at #{src_loc("4E60BC17")}: 'file' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[1].must_equal "Warning at #{src_loc("F7B16193")}: 'dir' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[2].must_equal "Warning at #{src_loc("CE17A7F3")}: 'src_spec' attribute not specified cleanly: 'a\\b' contains backslashes."
  op[:error].must_equal "Error at #{src_loc("CB2F8547")}: 'basename' attribute invalid - 'a\\b' must not contain slashes."
end
