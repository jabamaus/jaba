jtest "split_jdl_path" do
  parent, elem = JDL.split_jdl_path("a|b|c")
  parent.must_equal "a|b"
  elem.must_equal "c"
  JDL.split_jdl_path("a|b").must_equal ["a", "b"]
  JDL.split_jdl_path("*|b").must_equal ["*", "b"]
  JDL.split_jdl_path("a").must_equal [nil, "a"]
end

jtest "validates jdl paths" do
  JDL.node "node_0CD5F0E3"
  assert_jaba_error "'node_0CD5F0E3/a' is in invalid format." do
    JDL.attr "node_0CD5F0E3/a" # slashes not allowed
  end
  assert_jaba_error "'node_0CD5F0E3|a__b' is in invalid format." do
    JDL.attr "node_0CD5F0E3|a__b" # only 1 underscore allowed
  end
  assert_jaba_error "'node_0CD5F0E3|a b' is in invalid format." do
    JDL.attr "node_0CD5F0E3|a b" # spaces not allowed
  end
  assert_jaba_error "'node_0CD5F0E3||a_b' is in invalid format." do
    JDL.attr "node_0CD5F0E3||a_b" # double pipes not allowed
  end
  assert_jaba_error "'node_0CD5F0E3|a_b|' is in invalid format." do
    JDL.attr "node_0CD5F0E3|a_b|" # cannot end in pipe
  end
end

jtest "can register methods at top level" do
  JDL.method "meth_E5FBCDED" do
    on_called do Kernel.print "meth_E5FBCDED" end
  end
  assert_output "meth_E5FBCDED" do
    jaba do
      meth_E5FBCDED
    end
  end
end

jtest "can register methods globally" do
  JDL.node "node_5CD704E0"
  JDL.node "node_5CD704E0|node_AD7707C3"
  JDL.method "*|meth_124B8839" do
    on_called do Kernel.print "meth_124B8839|" end
  end
  assert_output "meth_124B8839|meth_124B8839|meth_124B8839|" do
    jaba do
      meth_124B8839
      node_5CD704E0 :n do
        meth_124B8839
      end
      node_5CD704E0 :n do
        node_AD7707C3 :n2 do
          meth_124B8839
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
  assert_jaba_error "Error at #{src_loc("2D0B33FE")}: 'b' attribute or method not defined." do
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
