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
    on_called do Kernel.print "meth_124B8839" end
  end
  assert_output "meth_124B8839" do
    jaba do
      meth_124B8839
    end
  end
  assert_output "meth_124B8839" do
    jaba do
      node_5CD704E0 :n do
        meth_124B8839
      end
    end
  end
  assert_output "meth_124B8839" do
    jaba do
      node_5CD704E0 :n do
        node_AD7707C3 :n2 do
          meth_124B8839
        end
      end
    end
  end
end
