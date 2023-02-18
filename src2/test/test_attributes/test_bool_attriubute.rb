JDL.node 'test_bool'
JDL.attr 'test_bool|bool_attr', type: :bool
JDL.attr 'test_bool|bool_attr_default_true', type: :bool do
  default true
end
JDL.attr 'test_bool|bool_attr_default_false', type: :bool do
  default false
end

jtest 'defaults to false' do
  jaba do
    test_bool :t do
      bool_attr.must_equal(false)
    end
  end
end

jtest 'requires default to be true or false' do
  e = assert_jaba_error "'invalid_default' attribute default invalid: '1' is a integer - expected [true|false]", ignore_trace: true do
    JDL.attr 'test_bool|invalid_default', type: :bool do
      default 1 # 2521765F
    end
  end
  e.backtrace[0].must_match(src_loc('2521765F'))
  jaba do
    test_bool :t do
      bool_attr_default_true.must_equal(true)
      bool_attr_default_false.must_equal(false)
    end
  end
end

jtest 'only allows boolean values' do
  assert_jaba_error "Error at #{src_loc('0108AEFB')}: 'b.bool_attr_default_false' attribute invalid: '1' is a integer - expected [true|false]" do
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
