jtest "compound attr not allowed a default" do
end

jtest "works with compound as single attribute" do
  jdl do
    attr "compound", type: :compound
    attr "compound|a" do default 10 end
    attr "compound|b"
    attr_array "compound|c" do default [1] end
    attr_hash "compound|d" do default(a: :b) end
  end
  op = jaba do
    # check defaults
    compound.a.must_equal 10
    compound.b.must_be_nil # no default value
    compound.c.must_equal [1]
    compound.d.must_equal({ a: :b })

    compound do # can be set in block form
      a 1
      b 2
      c 2
      d :c, :d
    end
    compound.a.must_equal 1
    compound.b.must_equal 2
    compound.c.must_equal [1, 2]
    compound.d.must_equal({ a: :b, c: :d })

    compound.b 3 # can set in object form
    compound.b.must_equal 3
    compound.d :e, :f
    compound.d.must_equal({ a: :b, c: :d, e: :f })

    compound do # repeated calls refer to same compound attr
      a 4
      b 5
      c [3, 4]
      d :e, :g
    end
    compound.a.must_equal 4
    compound.b.must_equal 5
    compound.c.must_equal [1, 2, 3, 4]
    compound.d.must_equal({ a: :b, c: :d, e: :g })

    compound.b 6
    compound.b.must_equal 6
    compound.c [5, 6]
    compound.c.must_equal [1, 2, 3, 4, 5, 6]
  end
  compound = op[:root][:compound]
  compound[:a].must_equal 4
  compound[:b].must_equal 6
  compound[:c].must_equal [1, 2, 3, 4, 5, 6]
  compound[:d].must_equal({ a: :b, c: :d, e: :g })
end

jtest "works with compound as single attribute with nesting" do
  jdl do
    attr "compound", type: :compound
    attr "compound|a" do default 1 end
    attr "compound|nested1", type: :compound
    attr "compound|nested1|b" do default 2 end
    attr "compound|nested1|nested2", type: :compound
    attr "compound|nested1|nested2|c" do default 3 end
  end
  op = jaba do
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
  compound = op[:root][:compound]
  compound[:a].must_equal 1
  compound[:nested1][:b].must_equal 2
  compound[:nested1][:nested2][:c].must_equal 5
end

jtest "has read only access to parent attrs" do
  jdl do
    attr :toplevel
    node :node
    attr "node|compound", type: :compound
  end
  jaba do
    toplevel 1
    node :n do
      compound do
        toplevel.must_equal 1
        JTest.assert_jaba_error "Error at #{JTest.src_loc("082F7661")}: Available in this context:\ntoplevel (read)" do
          toplevel 2 # 082F7661
        end
      end
    end
  end
end

jtest "works with array" do
  jdl do
    attr_array "compound", type: :compound
    attr "compound|a"
    attr "compound|b"
  end
  jaba do
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
