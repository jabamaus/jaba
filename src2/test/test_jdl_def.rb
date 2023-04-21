jtest "split_jdl_path" do
  parent, elem = JDL.core_jdl.send(:split_jdl_path, "a|b|c")
  parent.must_equal "a|b"
  elem.must_equal "c"
  JDL.core_jdl.send(:split_jdl_path, "a|b").must_equal ["a", "b"]
  JDL.core_jdl.send(:split_jdl_path, "*|b").must_equal ["*", "b"]
  JDL.core_jdl.send(:split_jdl_path, "a").must_equal [nil, "a"]
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
  jaba do
    # available_methods.must_equal ["m"] # TODO
    JTest.assert_output "m" do
      m
    end
  end
end

jtest "can register methods globally" do
  jdl do
    node "n1"
    node "n1|n2"
    method "*|m" do
      on_called do Kernel.print "m|" end
    end
  end
  assert_output "m|m|m|" do
    jaba do
      m
      n1 :n1 do
        m
      end
      n1 :n1a do
        n2 :n2 do
          m
        end
      end
    end
  end
end

jtest "can register attributes" do
  JDL.node "node_06E8272A"
  JDL.attr "node_06E8272A|a"
  JDL.attr "*|b" # registers into all nodes, except top level
  JDL.node "node_2026E63F"
  assert_jaba_error "Error at #{src_loc("2D0B33FE")}: 'b' attribute or method not defined. Available in this context:\ndefault_configs (rw)" do
    jaba do
      b 1 # 2D0B33FE
    end
  end
  jaba do
    node_06E8272A :n1 do
      a 1
      b 2
    end
    node_2026E63F :n2 do
      b 2
    end
  end
end

jtest "can register attributes as node options" do
  JDL.node "node_0A89C5E5"
  JDL.attr "node_0A89C5E5|a", type: :bool do
    flags :node_option
  end
  jaba do
    node_0A89C5E5 :n, a: true do
    end
  end
end

jtest "fails if flag does not exist" do
  JDL.node "node_C1FE3A1E"
  assert_jaba_error "Error at #{src_loc("01E55971")}: 'a' attribute invalid: ':unknown' flag does not exist." do
    JDL.attr "node_C1FE3A1E|a" do
      flags :unknown # 01E55971
    end
  end
end

jtest "fails if invalid basedir_spec specified" do
  JDL.node "node_C23D13C5"
  assert_jaba_error "Error at #{src_loc("EC9914E5")}: 'a' attribute invalid: ':unknown' basedir_spec must be one of [:jaba_file, :build_root, :buildsystem_root, :artefact_root]" do
    JDL.attr "node_C23D13C5|a", type: :dir do
      basedir_spec :unknown # EC9914E5
    end
  end
end
