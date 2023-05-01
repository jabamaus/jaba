jtest "defaults to false" do
  jdl do
    attr "a", type: :bool
  end
  jaba do
    a.must_be_false
  end
end

jtest "requires default to be true or false" do
  jdl do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("2521765F")}: 'invalid' attribute invalid - 'default' invalid - '1' is a integer - expected [true|false]" do
      attr "invalid", type: :bool do
        default 1 # 2521765F
      end
    end
    attr "b_true", type: :bool do
      default true
    end
    attr "b_false", type: :bool do
      default false
    end
  end
  jaba do
    b_true.must_be_true
    b_false.must_be_false
  end
end

jtest "only allows boolean values" do
  jdl do
    attr "b", type: :bool
  end
  assert_jaba_file_error "'b' attribute invalid - '1' is a integer - expected [true|false]", "0108AEFB" do
    "b 1 # 0108AEFB"
  end
end

jtest "works with required flag" do
  jdl do
    node "node"
    attr "node/b" do
      flags :required
    end
  end
  assert_jaba_file_error "'b' attribute requires a value.", "3C869B0D" do
    "node :n # 3C869B0D"
  end
end

jtest "can be set from cmdline" do
  jdl do
    attr :b1, type: :bool
    attr :b2, type: :bool
    attr :b3, type: :bool
    attr :b4, type: :bool
  end
  jaba(
    global_attrs_from_cmdline: { 'b1': "true", 'b2': "false", 'b3': "1", 'b4': "0" }
    ) do
    b1.must_equal true
    b2.must_equal false
    b3.must_equal true
    b4.must_equal false
  end

  op = jaba(global_attrs_from_cmdline: { 'b1': 10 }, want_exceptions: false)
  op[:error].must_equal "Error: '10' invalid value for 'b1' attribute - [true|false|0|1] expected."
end
