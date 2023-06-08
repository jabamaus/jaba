jtest "checks path is valid" do
  jdl do
    attr "file", type: :file
    attr "dir", type: :dir
    attr "src", type: :src
    attr "basename", type: :basename
  end
  op = jaba(want_exceptions: false) do
    file "a\\b", :force # 4E60BC17
    dir "a\\b", :force # F7B16193
    src "a\\b", :force # CE17A7F3
    basename "a\\b" # CB2F8547
  end
  w = op[:warnings]
  w.size.must_equal 3
  w[0].must_equal "Warning at #{src_loc("4E60BC17")}: 'file' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[1].must_equal "Warning at #{src_loc("F7B16193")}: 'dir' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[2].must_equal "Warning at #{src_loc("CE17A7F3")}: 'src' attribute not specified cleanly: 'a\\b' contains backslashes."
  op[:error].must_equal "Error at #{src_loc("CB2F8547")}: 'basename' attribute invalid - 'a\\b' must not contain slashes."
end

jtest "only array attrs can accept wildcards" do
  jdl do
    attr :files, variant: :array, type: :file
    attr :file, type: :file
  end
  jaba do
    files "*.cpp", :force
    JTest.assert_jaba_error "Error at #{JTest.src_loc("FA5CC57C")}: 'file' attribute invalid - only array attributes can accept wildcards." do
      file "*.cpp", :force # FA5CC57C
    end
  end
end

jtest "top level paths are made absolute based on base_attr" do
  dir = __dir__
  jdl do
    attr :f1, type: :file
    attr :d1, type: :dir
    attr :f2, type: :file do
      flags :no_check_exist
      base_attr :d2
    end
    attr :d2, type: :dir do
      flags :no_check_exist
      base_attr :d3
    end
    attr :d3, type: :dir
  end
  jaba do
    f1 "a", :force
    f1.must_equal "#{dir}/a"
    f2.must_equal "" # f2's base_attr has not been set yet so should be empty
    d1 "b", :force
    d3 "c", :force
    d2.must_equal "#{dir}/c" # d2 based on d3
    d2 "d", :force
    d2.must_equal "#{dir}/c/d" # d2 based on d3
    f2 "../e", :force
    f2.must_equal "#{dir}/c/e"
  end
end

jtest "base_attr must be of type dir" do
  jdl do
    attr :a, type: :file do
      base_attr :b
    end
    attr :b, type: :file
  end
  assert_jaba_error "Error at #{src_loc("EC9914E5")}: 'a' attribute has 'b' attribute as its base dir but 'b' attribute is of type 'file' but must be ':dir'." do
    jaba do
      b "c", :force
      a "d", :force # EC9914E5
    end
  end
end

jtest "paths are made absolute" do
  dir = __dir__
  jdl do
    node :node
    attr "node/file1", type: :file do
      flags :no_check_exist
      base_attr :root
    end
    attr "node/dir1", type: :dir do
      flags :no_check_exist
      base_attr :root
    end
    attr "node/file2", type: :file do # based on value of another attr
      flags :no_check_exist
      base_attr :dir1
    end
  end
  jaba do
    node :n1 do
      root.must_equal(dir)
      file1 "../a", :force
      file1.must_equal "#{dir.parent_path}/a"
      dir1 "c/d", :force
      dir1.must_equal "#{dir}/c/d"
      file2 "../e", :force
      file2.must_equal "#{dir}/c/e" # based off val of file1
    end
    #node :n2, root: "b" do
    #  root.must_equal("#{dir}/b")
    #  file1 "../a", :force
    #  file1.must_equal "#{dir}/a"
    #end
  end
end
