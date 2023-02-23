JDL.node "test_attr_single"
JDL.attr "test_attr_single|single"

jtest "only accepts single values" do
  e = assert_jaba_error "'default' expects a single value but got '[]'.", ignore_trace: true do
    JDL.attr 'test_attr_single|single_invalid_default' do
      default [] # 787CC36C
    end
  end
  e.backtrace[0].must_match(src_loc("787CC36C"))

  assert_jaba_error "Error at #{src_loc('6D4B452C')}: 't.single' attribute invalid: 'single' attribute must be a single value not a 'Array'." do
    jaba do
      test_attr_single :t do
        single [1, 2] # 6D4B452C
      end
    end
  end
end