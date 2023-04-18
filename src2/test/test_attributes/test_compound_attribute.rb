jtest "compound attr" do
  JDL.node "node_38E8D01A"
  JDL.attr "node_38E8D01A|compound", type: :compound
  JDL.attr "node_38E8D01A|compound|a"
  JDL.attr "node_38E8D01A|compound|b"
  op = jaba do
    node_38E8D01A :n do
      compound do
        a 1
        b 2
      end
    end
  end
  n = op[:root].children[0]
  n[:compound][:a].must_equal 1
end
