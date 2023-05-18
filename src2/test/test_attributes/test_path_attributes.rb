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

# TODO: check base_dir is a dir attr
jtest "top level paths are made absolute based on basedir spec" do
  dir = __dir__
  jdl do
    attr :f1, type: :file
    attr :d1, type: :dir
    attr :f2, type: :file do
      basedir do
        d2
      end
    end
    attr :d2, type: :dir do
      basedir do
        d3
      end
    end
    attr :d3, type: :dir
  end
  jaba do
    f1 "a"
    f1.must_equal "#{dir}/a"
    d1 "b"
    d3 "c"
    d2.must_equal "#{dir}/c" # d2 based on d3
    d2 "d"
    d2.must_equal "#{dir}/c/d" # d2 based on d3
    f2 "../e"
    f2.must_equal "#{dir}/c/e"
  end
end

jtest "paths are made absolute" do
  dir = __dir__
  jdl do
    node :node
    attr "node/file1", type: :file do
      basedir :definition_root
    end
    attr "node/dir1", type: :dir do
      basedir :definition_root
    end
    attr "node/file2", type: :file do # based on value of another attr
      basedir do
        dir1
      end
    end
  end
  jaba do
    node :n1 do
      root.must_equal(dir)
      file1 "../a"
      file1.must_equal "#{dir.parent_path}/a"
      dir1 "c/d"
      dir1.must_equal "#{dir}/c/d"
      file2 "../e"
      file2.must_equal "#{dir}/c/e" # based of val of file1
    end
    node :n2, root: "b" do
      root.must_equal("#{dir}/b")
      file1 "../a"
      file1.must_equal "#{dir}/a"
    end
  end
end
