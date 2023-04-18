 jtest "compound attr not allowed a default" do
 end

 jtest "works with compound as single attribute" do
  JDL.node "node_38E8D01A"
  JDL.attr "node_38E8D01A|compound", type: :compound
  JDL.attr "node_38E8D01A|compound|a" do default 10 end
  JDL.attr "node_38E8D01A|compound|b"
  JDL.attr_array "node_38E8D01A|compound|c" do default [1] end
  JDL.attr_hash "node_38E8D01A|compound|d" do default(a: :b) end
  
  op = jaba do
    node_38E8D01A :n do
      # check defaults
      compound.a.must_equal 10
      compound.b.must_be_nil # no default value
      compound.c.must_equal [1] 
      compound.d.must_equal({a: :b})

      compound do # can be set in block form
        a 1
        b 2
        c 2
        d :c, :d
      end
      compound.a.must_equal 1
      compound.b.must_equal 2
      compound.c.must_equal [1, 2]
      compound.d.must_equal({a: :b, c: :d})

      compound.b 3 # can set in object form
      compound.b.must_equal 3
      compound.d :e, :f
      compound.d.must_equal({a: :b, c: :d, e: :f})

      compound do # repeated calls refer to same compound attr
        a 4
        b 5
        c [3, 4]
        d :e, :g
      end
      compound.a.must_equal 4
      compound.b.must_equal 5
      compound.c.must_equal [1, 2, 3, 4]
      compound.d.must_equal({a: :b, c: :d, e: :g})

      compound.b 6
      compound.b.must_equal 6
      compound.c [5, 6]
      compound.c.must_equal [1, 2, 3, 4, 5, 6]
    end 
  end
  n = op[:root].children[0]
  n[:compound][:a].must_equal 4
  n[:compound][:b].must_equal 6
  n[:compound][:c].must_equal [1, 2, 3, 4, 5, 6]
  n[:compound][:d].must_equal({a: :b, c: :d, e: :g})
end

jtest "works with compound as single attribute with nesting" do
  JDL.node "node_38E8D01A"
  JDL.attr "node_38E8D01A|compound", type: :compound
  JDL.attr "node_38E8D01A|compound|a" do default 1 end
  JDL.attr "node_38E8D01A|compound|nested1", type: :compound
  JDL.attr "node_38E8D01A|compound|nested1|b" do default 2 end
  JDL.attr "node_38E8D01A|compound|nested1|nested2", type: :compound
  JDL.attr "node_38E8D01A|compound|nested1|nested2|c" do default 3 end

  op = jaba do
    node_38E8D01A :n do
      compound.nested1.nested2.c.must_equal 3
      compound.nested1.b.must_equal 2
      compound.a.must_equal 1
      compound do
        nested1 do
          nested2 do
            c 4
          end
        end
      end
      compound.nested1.nested2.c.must_equal 4
      compound.nested1.nested2.c 5
      compound.nested1.nested2.c.must_equal 5
    end
  end
  n = op[:root].children[0]
  n[:compound][:a].must_equal 1
  n[:compound][:nested1][:b].must_equal 2
  n[:compound][:nested1][:nested2][:c].must_equal 5
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
