jtest "split_jdl_path" do
  b = JABA::JDLBuilder.new
  parent, elem = b.send(:split_jdl_path, "a|b|c")
  parent.must_equal "a|b"
  elem.must_equal "c"
  b.send(:split_jdl_path, "a|b").must_equal ["a", "b"]
  b.send(:split_jdl_path, "*|b").must_equal ["*", "b"]
  b.send(:split_jdl_path, "a").must_equal [nil, "a"]
end

jtest "validates jdl paths" do
  jdl do
    node "n"
    JTest.assert_jaba_error "'n/a' is in invalid format." do
      attr "n/a" # slashes not allowed
    end
    JTest.assert_jaba_error "'n|a__b' is in invalid format." do
      attr "n|a__b" # only 1 underscore allowed
    end
    JTest.assert_jaba_error "'n|a b' is in invalid format." do
      attr "n|a b" # spaces not allowed
    end
    JTest.assert_jaba_error "'n||a_b' is in invalid format." do
      attr "n||a_b" # double pipes not allowed
    end
    JTest.assert_jaba_error "'n|a_b|' is in invalid format." do
      attr "n|a_b|" # cannot end in pipe
    end
  end
end

jtest "can register methods at top level" do
  jdl do
    method "m" do
      on_called do Kernel.print "m" end
    end
  end
  assert_output "m" do
    jaba do
      # TODO: add support for available_methods
      # available_methods.must_equal ["m"] # TODO
      m
    end
  end
end

jtest "can register methods globally" do
  jdl do
    node "node1"
    node "node1|node2"
    method "*|m" do
      on_called do Kernel.print "m|" end
    end
  end
  assert_output "m|m|m|" do
    jaba do
      m
      node1 :n1 do
        m
      end
      node1 :n1a do
        node2 :n2 do
          m
        end
      end
    end
  end
end

jtest "can register attributes into nodes" do
  jdl do
    node "node1"
    attr "node1|a"
    attr "*|b" # registers into all nodes, except top level
    node "node2"
  end
  # TODO: it is not possible to use one jaba context and call assert_jaba_error because correct exception
  # handling relies on exception handler called at the end of jaba context, which never gets called.
  # Maybe all exception processing code could be moved to JABA.error?
  assert_jaba_error "Error at #{src_loc("2D0B33FE")}: 'b' attribute or method not defined. Available in this context: none." do
    jaba do
      b 1 # 2D0B33FE
    end
  end
  jaba do
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
    attr "node|a", type: :bool do
      flags :node_option
    end
  end
  jaba do
    node :n, a: true do
    end
  end
end

jtest "fails if flag does not exist" do
  assert_jaba_error "Error at #{src_loc("01E55971")}: 'a' attribute invalid: ':unknown' flag does not exist." do
    jdl do
      attr "a" do
        flags :unknown # 01E55971
      end
    end
  end
end

jtest "fails if invalid basedir_spec specified" do
  assert_jaba_error "Error at #{src_loc("EC9914E5")}: 'a' attribute invalid: ':unknown' basedir_spec must be one of [:jaba_file, :build_root, :buildsystem_root, :artefact_root]" do
    jdl do
      attr "a", type: :dir do
        basedir_spec :unknown # EC9914E5
      end
    end
  end
end
