 jtest "compound attr" do
  JDL.node "node_38E8D01A"
  JDL.attr "node_38E8D01A|compound", type: :compound
  JDL.attr "node_38E8D01A|compound|a"
  JDL.attr "node_38E8D01A|compound|b"
  JDL.attr "node_38E8D01A|compound|nested", type: :compound
  JDL.attr "node_38E8D01A|compound|nested|c"
  JDL.attr "node_38E8D01A|compound|nested|d"
  
  op = jaba do
    node_38E8D01A :n do
      compound do
        a 1
        b 2
        nested do
          c 3
          d 4
        end
        nested.c.must_equal 3
        nested.d.must_equal 4
      end
      compound.a.must_equal 1
      compound.b.must_equal 2
      compound.nested.c.must_equal 3
      compound.nested.d.must_equal 4
      compound.b 5
      compound.b.must_equal 5
      compound.nested.c 6
      compound.nested.d 7
      compound.nested.c.must_equal 6
      compound.nested.d.must_equal 7
    end 
  end
  n = op[:root].children[0]
  n[:compound][:a].must_equal 1
  n[:compound][:b].must_equal 5
  n[:compound][:nested][:c].must_equal 6
  n[:compound][:nested][:d].must_equal 7
end

jtest "works with array" do
  JDL.node "node_B722D074"
  JDL.attr_array "node_B722D074|compound", type: :compound
  JDL.attr "node_B722D074|compound|a"
  JDL.attr "node_B722D074|compound|b"
  jaba do
    node_B722D074 :n do
      compound do
        a 1
        b 2
      end
      compound do
        a 3
        b 4
      end
      compound do
        a 5
        b 6
      end
      compound.size.must_equal 3
    end
  end
end
