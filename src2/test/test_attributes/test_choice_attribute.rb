JDL.node "test_choice_attribute"

jtest "requires items to be set" do
  assert_jaba_error "Error at #{src_loc("A2047AFC")}: 'a' attribute invalid: 'items' must be set.", ignore_trace: true do
    JDL.attr "test_choice_attribute|a", type: :choice # A2047AFC
  end
end

jtest "warns if items contains duplicates" do
  assert_jaba_warn "'items' contains duplicates", __FILE__, "234928DC" do
    JDL.attr "test_choice_attribute|b", type: :choice do
      items [:a, :a, :b, :b] # 234928DC
    end
  end
end
