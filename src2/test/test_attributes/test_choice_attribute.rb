JDL.node "test_choice_attribute"

jtest "requires items to be set" do
  assert_jaba_error "Error at #{src_loc("A2047AFC")}: 'a' attribute invalid: 'items' must be set.", ignore_trace: true do
    JDL.attr "test_choice_attribute|a", type: :choice # A2047AFC
  end
end
