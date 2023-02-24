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

jtest "requires default to be in items" do
  assert_jaba_error "Error at #{src_loc("8D88FA0D")}: 'c' attribute invalid: 'default' invalid: Must be one of [1, 2, 3] but got '4'.", ignore_trace: true do
    JDL.attr "test_choice_attribute|c", type: :choice do
      items [1, 2, 3]
      default 4 # 8D88FA0D
    end
  end
  #  assert_jaba_error "Error at #{src_loc('CDCFF3A7')}: ':a' array attribute default invalid: Must be one of [1, 2, 3] but got '4'. See #{src_loc('0C81C8C8')}." do
  #    jaba(barebones: true) do
  #      type :test do
  #        attr_array :a, type: :choice do
  #          items [1, 2, 3] # 0C81C8C8
  #          default [1, 2, 4] # CDCFF3A7
  #        end
  #      end
  #    end
  #  end
end
