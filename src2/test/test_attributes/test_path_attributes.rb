jtest "checks path is valid" do
  jdl do
    attr "file", type: :file
    attr "dir", type: :dir
    attr "src", type: :src
    attr "basename", type: :basename
  end
  op = jaba(want_exceptions: false) do
    file "a\\b" # 4E60BC17
    dir "a\\b" # F7B16193
    src "a\\b" # CE17A7F3
    basename "a\\b" # CB2F8547
  end
  w = op[:warnings]
  w.size.must_equal 3
  w[0].must_equal "Warning at #{src_loc("4E60BC17")}: 'file' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[1].must_equal "Warning at #{src_loc("F7B16193")}: 'dir' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[2].must_equal "Warning at #{src_loc("CE17A7F3")}: 'src' attribute not specified cleanly: 'a\\b' contains backslashes."
  op[:error].must_equal "Error at #{src_loc("CB2F8547")}: 'basename' attribute invalid - 'a\\b' must not contain slashes."
end

jtest "paths are made absolute" do
  dir = __dir__
  jdl do
    attr "*/root", type: :dir do
      flags :node_option
      basedir_spec :jaba_file
    end
    node :node
    attr "node/file", type: :file do
      basedir_spec :definition_root
    end
    attr "node/dir", type: :dir do
      basedir_spec :definition_root
    end
    attr "node/src", type: :src do
      basedir_spec :definition_root
    end
    attr "node/basename", type: :basename
  end
  jaba do
    node :n1 do
      root.must_equal(dir)
      file "../a"
      file.must_equal "#{dir.parent_path}/a"
    end
    node :n2, root: "b" do
      root.must_equal(dir)
      file "../a"
      file.must_equal "#{dir}/a"
    end
  end
end
