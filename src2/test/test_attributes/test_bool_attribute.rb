JDL.node "test_bool"
JDL.attr "test_bool|bool_attr", type: :bool
JDL.attr "test_bool|bool_attr_default_true", type: :bool do
  default true
end
JDL.attr "test_bool|bool_attr_default_false", type: :bool do
  default false
end

jtest "defaults to false" do
  jaba do
    test_bool :t do
      bool_attr.must_equal(false)
    end
  end
end

jtest "requires default to be true or false" do
  assert_jaba_error "Error at #{src_loc("2521765F")}: 'invalid_default' attribute invalid: 'default' invalid: '1' is a integer - expected [true|false]" do
    JDL.attr "test_bool|invalid_default", type: :bool do
      default 1 # 2521765F
    end
  end
  jaba do
    test_bool :t do
      bool_attr_default_true.must_equal(true)
      bool_attr_default_false.must_equal(false)
    end
  end
end

jtest "only allows boolean values" do
  assert_jaba_file_error "'b.bool_attr_default_false' attribute invalid: '1' is a integer - expected [true|false]", "0108AEFB" do
    %Q{
test_bool :b do
  bool_attr_default_false 1 # 0108AEFB
end
}
  end
  jaba do
    test_bool :t do
      bool_attr_default_true false
      bool_attr_default_false true
      bool_attr_default_true.must_equal(false)
      bool_attr_default_false.must_equal(true)
    end
  end
end

JDL.node "test_bool_required"
JDL.attr "test_bool_required|bool_attr", type: :bool do
  flags :required
end

jtest "works with required flag" do
  assert_jaba_file_error "'t.bool_attr' attribute requires a value.", "3C869B0D" do
    %Q{
test_bool_required :t do # 3C869B0D
end
}
  end
end

JDL.attr "global_bool1", type: :bool do
  default false
end

JDL.attr "global_bool2", type: :bool do
  default true
end

JDL.attr "global_bool3", type: :bool do
  default false
end

JDL.attr "global_bool4", type: :bool do
  default true
end

jtest "can be set from global_attrs" do
  output = jaba(global_attrs: {
                  'global_bool1': "true",
                  'global_bool2': false,
                  'global_bool3': "1",
                  'global_bool4': 0,
                }) do
    global_bool1.must_equal true
    global_bool2.must_equal false
    global_bool3.must_equal true
    global_bool4.must_equal false
  end

  root = output[:root]
  root.get_attr("global_bool1").value.must_equal true
  root.get_attr("global_bool2").value.must_equal false
  root.get_attr("global_bool3").value.must_equal true
  root.get_attr("global_bool4").value.must_equal false

  op = jaba(global_attrs: { 'global_bool1': "10" }, want_exceptions: false)
  op[:error].must_equal "Error: '10' invalid value for 'global_bool1' attribute - [true|false|0|1] expected."
end
