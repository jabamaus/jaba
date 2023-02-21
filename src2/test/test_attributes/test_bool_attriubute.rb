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
  e = assert_jaba_error "'invalid_default' attribute default invalid: '1' is a integer - expected [true|false]", ignore_trace: true do
    JDL.attr "test_bool|invalid_default", type: :bool do
      default 1 # 2521765F
    end
  end
  e.backtrace[0].must_match(src_loc("2521765F"))
  jaba do
    test_bool :t do
      bool_attr_default_true.must_equal(true)
      bool_attr_default_false.must_equal(false)
    end
  end
end

jtest "only allows boolean values" do
  assert_jaba_error "Error at #{src_loc("0108AEFB")}: 'b.bool_attr_default_false' attribute invalid: '1' is a integer - expected [true|false]" do
    jaba do
      test_bool :b do
        bool_attr_default_false 1 # 0108AEFB
      end
    end
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
  assert_jaba_error "Error at #{src_loc('3C869B0D')}: 't.bool_attr' attribute requires a value." do
    jaba do
      test_bool_required :t do # 3C869B0D
      end
    end
  end
end
=begin
jtest 'can be set from global_attrs' do
  jaba(barebones: true, global_attrs: {
    'a1': 'true',
    'a2': false,
    'a3': '1',
    'a4': 0
    }) do
    open_type :globals do
      attr :a1, type: :bool do
        default false
      end
      attr :a2, type: :bool do
        default true
      end
      attr :a3, type: :bool do
        default false
      end
      attr :a4, type: :bool do
        default true
      end
    end
    type :test
    test :t do
      globals.a1.must_equal true
      globals.a2.must_equal false
      globals.a3.must_equal true
      globals.a4.must_equal false
    end
  end

  op = jaba(barebones: true, global_attrs: {'a': '10'}, want_exceptions: false) do
    open_type :globals do
      attr :a, type: :bool
    end
  end
  op[:error].must_equal "'10' invalid value for ':a' attribute - [true|false|0|1] expected"
end
=end
