jtest "validates default" do
  jdl do
    attr :a, type: :int do
      default "not an int" # 9A0B23C7
    end
  end
  assert_jaba_error "Error at #{src_loc("9A0B23C7")}: 'a' attribute invalid - 'default' invalid - 'not an int' is a string - expected an integer." do
    jaba do end
  end
end

jtest "validates value" do
  jdl do
    attr :a, type: :int
  end
  assert_jaba_error "Error at #{src_loc("F616E4F3")}: 'a' attribute invalid - 'true' is a boolean - expected an integer." do
    jaba do
      a true # F616E4F3
    end
  end
end

jtest "fails if value not supplied when 'required' flag specified" do
  jdl do
    attr :a, type: :int do
      flags :required
    end
  end
  assert_jaba_error "Error at #{src_loc("D43F2208")}: 'top_level' requires 'a' attribute to be set." do
    jaba do end # D43F2208
  end
  # Also test file version
  assert_jaba_file_error "'top_level' requires 'a' attribute to be set.", "8CF3DCA2" do
    "# 8CF3DCA2"
  end
end

jtest "supports standard ops" do
  jdl do
    attr :a, type: :int
    attr :b, type: :int do
      default 1
    end
    attr_array :aa, type: :int
    attr_array :ba, type: :int do
      default [3, 4, 5]
    end
    attr_hash :ah, type: :int, key_type: :string
    attr_hash :bh, type: :int, key_type: :string do
      default({ k1: 1 })
    end
  end
  jaba do
    a.must_equal 0 # Defaults to 0 if :required flag not used
    b.must_equal 1 # Works with a default
    a 2
    a.must_equal 2
    b 3
    b.must_equal 3

    # test array attrs
    aa.must_equal []
    aa [1, 2, 3]
    aa.must_equal [1, 2, 3]
    ba.must_equal [3, 4, 5]
    ba [6, 7, 8]
    ba.must_equal [3, 4, 5, 6, 7, 8]

    # test hash attrs
    ah.must_equal({})
    ah :k1, 1
    ah.must_equal({ k1: 1 })
    bh.must_equal({ k1: 1 })
    bh :k1, 2
    bh.must_equal({ k1: 2 })
    bh :k2, 3
    bh.must_equal({ k1: 2, k2: 3 })
  end
end

jtest "can be set from cmdline" do
  jdl do
    attr :a, type: :int
    attr :b, type: :int
    attr :c, type: :int
    attr :d, type: :int
  end
  jaba(global_attrs_from_cmdline: {
         'a': "1",
         'b': "3433409",
         'c': "-1",
         'd': "0",
       }) do
    a.must_equal(1)
    b.must_equal(3433409)
    c.must_equal(-1)
    d.must_equal(0)
  end

  op = jaba(global_attrs_from_cmdline: { 'a': "foo" }, want_exceptions: false) do end
  op[:error].must_equal "Error: 'foo' invalid value for 'a' attribute - integer expected."
end
