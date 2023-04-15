jtest "can register methods at top level" do
  JDL.method "meth_E5FBCDED", scope: :top_level do
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
  JDL.method "meth_124B8839", scope: :global do
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
