JDL.node "test_attr_single"
JDL.attr "test_attr_single|single"
JDL.attr "test_attr_single|a"
JDL.attr "test_attr_single|b"
JDL.attr "test_attr_single|read_only" do
  flags :read_only
  default 1
end

jtest "only accepts single values" do
  e = assert_jaba_error "'default' expects a single value but got '[]'.", ignore_trace: true do
    JDL.attr "test_attr_single|single_invalid_default" do
      default [] # 787CC36C
    end
  end
  e.backtrace[0].must_match(src_loc("787CC36C"))

  assert_jaba_error "Error at #{src_loc("6D4B452C")}: 't.single' attribute invalid: 'single' attribute must be a single value not a 'Array'." do
    jaba do
      test_attr_single :t do
        single [1, 2] # 6D4B452C
      end
    end
  end
end

jtest "allows setting value with block" do
  jaba do
    test_attr_single :t do
      b 1
      a do
        b + 1
      end
      a.must_equal 2
    end
  end
end

jtest 'rejects modifying returned values' do
  assert_jaba_error "Error at #{src_loc('45925C07')}: Can't modify read only String: \"b\"", ignore_trace: true do
    jaba do
      test_attr_single :t do
        a +('b')
        val = a
        val.upcase! # 45925C07
      end
    end
  end
end

jtest 'rejects modifying read only attributes' do
  assert_jaba_error "Error at #{src_loc('D4AE68B1')}: 't.read_only' attribute is read only." do
    jaba do
      test_attr_single :t do
        read_only.must_equal(1)
        read_only 2 # D4AE68B1
      end
    end
  end
end