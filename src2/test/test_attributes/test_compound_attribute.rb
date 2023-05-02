jtest "compound attr not allowed a default" do
end

jtest "works with compound as single attribute" do
  jdl do
    attr "cmpd", type: :compound
    attr "cmpd/a" do default 10 end
    attr "cmpd/b"
    attr_array "cmpd/c" do default [1] end
    attr_hash "cmpd/d", key_type: :string do default(a: :b) end
  end
  op = jaba do
    # check defaults
    cmpd.a.must_equal 10
    cmpd.b.must_be_nil # no default value
    cmpd.c.must_equal [1]
    cmpd.d.must_equal({ a: :b })

    cmpd do # can be set in block form
      a 1
      b 2
      c 2
      d :c, :d
    end
    cmpd.a.must_equal 1
    cmpd.b.must_equal 2
    cmpd.c.must_equal [1, 2]
    cmpd.d.must_equal({ a: :b, c: :d })

    cmpd.b 3 # can set in object form
    cmpd.b.must_equal 3
    cmpd.d :e, :f
    cmpd.d.must_equal({ a: :b, c: :d, e: :f })

    cmpd do # repeated calls refer to same compound attr
      a 4
      b 5
      c [3, 4]
      d :e, :g
    end
    cmpd.a.must_equal 4
    cmpd.b.must_equal 5
    cmpd.c.must_equal [1, 2, 3, 4]
    cmpd.d.must_equal({ a: :b, c: :d, e: :g })

    cmpd.b 6
    cmpd.b.must_equal 6
    cmpd.c [5, 6]
    cmpd.c.must_equal [1, 2, 3, 4, 5, 6]
  end
  cmpd = op[:root][:cmpd]
  cmpd[:a].must_equal 4
  cmpd[:b].must_equal 6
  cmpd[:c].must_equal [1, 2, 3, 4, 5, 6]
  cmpd[:d].must_equal({ a: :b, c: :d, e: :g })
end

jtest "works with compound as single attribute with nesting" do
  jdl do
    attr "cmpd", type: :compound
    attr "cmpd/a" do default 1 end
    attr "cmpd/nested1", type: :compound
    attr "cmpd/nested1/b" do default 2 end
    attr "cmpd/nested1/nested2", type: :compound
    attr "cmpd/nested1/nested2/c" do default 3 end
  end
  op = jaba do
    cmpd.nested1.nested2.c.must_equal 3
    cmpd.nested1.b.must_equal 2
    cmpd.a.must_equal 1
    cmpd do
      nested1 do
        nested2 do
          c 4
        end
      end
    end
    cmpd.nested1.nested2.c.must_equal 4
    cmpd.nested1.nested2.c 5
    cmpd.nested1.nested2.c.must_equal 5
  end
  cmpd = op[:root][:cmpd]
  cmpd[:a].must_equal 1
  cmpd[:nested1][:b].must_equal 2
  cmpd[:nested1][:nested2][:c].must_equal 5
end

jtest "has read only access to parent attrs" do
  jdl do
    attr :toplevel
    node :node
    attr "node/cmpd", type: :compound
  end
  jaba do
    toplevel 1
    node :n do
      cmpd do
        toplevel.must_equal 1
        JTest.assert_jaba_error "Error at #{JTest.src_loc("082F7661")}: 'toplevel' attribute is read only in this scope." do
          toplevel 2 # 082F7661
        end
      end
    end
  end
end

jtest "works with array" do
  jdl do
    attr_array "cmpd", type: :compound
    attr "cmpd/a"
    attr "cmpd/b"
  end
  jaba do
    cmpd do
      a 1
      b 2
    end
    cmpd do
      a 3
      b 4
    end
    cmpd do
      a 5
      b 6
    end
    cmpd.size.must_equal 3
  end
end
