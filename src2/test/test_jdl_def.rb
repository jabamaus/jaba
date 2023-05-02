jtest "split_jdl_path" do
  b = JABA::JDLBuilder.new([])
  parent, elem = b.send(:split_jdl_path, "a/b/c")
  parent.must_equal "a/b"
  elem.must_equal "c"
  b.send(:split_jdl_path, "a/b").must_equal ["a", "b"]
  b.send(:split_jdl_path, "*/b").must_equal ["*", "b"]
  b.send(:split_jdl_path, "a").must_equal [nil, "a"]
end

jtest "validates jdl path format" do
  jdl(blank: true) do
    node :n
    JTest.assert_jaba_error "Error at #{JTest.src_loc("5CFB9574")}: 'n|a' is in invalid format." do
      attr "n|a" # 5CFB9574 pipes not allowed
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("9B9B965C")}: 'n/a__b' is in invalid format." do
      attr "n/a__b" # 9B9B965C only 1 underscore allowed
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("C42FF3D2")}: 'n/a b' is in invalid format." do
      attr "n/a b" # C42FF3D2 spaces not allowed
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("B90811C7")}: 'n//a_b' is in invalid format." do
      attr "n//a_b" # B90811C7 double slashes not allowed
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("D54FA196")}: 'n/a_b/' is in invalid format." do
      attr "n/a_b/" # D54FA196 cannot end in slash
    end
  end
  jaba
end

jtest "checks parent path valid" do
  jdl(blank: true) do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("24DB3815")}: No 'a' node registered." do
      attr "a/b" # 24DB3815
    end
  end
  jaba
end

jtest "checks for duplicate paths" do
  jdl(apis: [:attr_types]) do
    node "n"
    JTest.assert_jaba_error "Error at #{JTest.src_loc("99E1CB75")}: Duplicate 'n' node registered." do
      node "n" # 99E1CB75
    end
    attr "n/a"
    JTest.assert_jaba_error "Error at #{JTest.src_loc("BC9DD62C")}: Duplicate 'n/a' attribute registered." do
      attr "n/a" # BC9DD62C
    end
    method "n/m" do
      on_called do end
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("87285F34")}: Duplicate 'n/m' method registered." do
      method "n/m" # 87285F34
    end
  end
  jaba
end

jtest "can register methods at top level" do
  jdl(apis: [:attr_types, :core]) do
    method :m do
      on_called do Kernel.print "m" end
    end
  end
  jaba do
    available.must_equal ["available", "fail", "glob", "include", "m", "print", "puts", "shared"]
    JTest.assert_output "m" do
      m
    end
  end
end

jtest "can register methods into a specific node" do
  jdl(blank: true) do
    node :node
    method "node/m" do
      on_called do Kernel.print "m" end
    end
  end
  jaba do
    node :n do
      JTest.assert_output "m" do
        m
      end
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("527A4B81")}: 'm' attr/method not defined. Available in this scope: none." do
      m # 527A4B81
    end
  end
end

jtest "can register methods globally" do
  jdl(blank: true) do
    node "node1"
    node "node2"
    method "*/m" do
      on_called do Kernel.print "m|" end
    end
  end
  assert_output "m|m|m|" do
    jaba do
      m
      node1 :n1 do
        m
      end
      node2 :n2 do
        m
      end
    end
  end
end

jtest "can register attributes into nodes" do
  jdl(apis: [:attr_types]) do
    node "node1"
    attr "node1/a"
    attr "*/b" # registers into all nodes, except top level
    node "node2"
  end
  jaba do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("2D0B33FE")}: 'b' attr/method not defined. Available in this scope: none." do
      b 1 # 2D0B33FE
    end
    node1 :n1 do
      a 1
      b 2
    end
    node2 :n2 do
      b 2
    end
  end
end

jtest "can register attributes as node options" do
  jdl do
    node "node"
    attr "node/a", type: :bool do
      flags :node_option
    end
  end
  jaba do
    node :n, a: true
  end
end

jtest "fails if attribute type does not exist" do
  assert_jaba_error "Error at #{src_loc("CE16AD90")}: 'a' attribute invalid - ':unknown' must be one of [:null, :string, :symbol, :symbol, :bool, :choice, :uuid, :file, :dir, :basename, :src, :compound]" do
    jdl do
      attr :a, type: :unknown # CE16AD90
    end
    jaba
  end
end

jtest "fails if flag does not exist" do
  assert_jaba_error "Error at #{src_loc("01E55971")}: 'a' attribute invalid - ':unknown' must be one of [:allow_dupes, :no_sort, :node_option, :per_project, :per_config, :read_only, :required]" do
    jdl do
      attr "a" do
        flags :unknown # 01E55971
      end
    end
    jaba
  end
end

jtest "fails if invalid basedir_spec specified" do
  assert_jaba_error "Error at #{src_loc("EC9914E5")}: 'a' attribute invalid - ':unknown' must be one of [:jaba_file, :build_root, :buildsystem_root, :artefact_root]" do
    jdl do
      attr "a", type: :dir do
        basedir_spec :unknown # EC9914E5
      end
    end
    jaba
  end
end
