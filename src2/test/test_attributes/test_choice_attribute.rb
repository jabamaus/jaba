JDL.node "test_choice_attribute"

jtest "requires items to be set" do
  assert_jaba_error "Error at #{src_loc("A2047AFC")}: 'a' attribute invalid: 'items' must be set." do
    JDL.attr "test_choice_attribute|a", type: :choice # A2047AFC
  end
end

jtest "warns if items contains duplicates" do
  assert_output "Warning at #{src_loc("234928DC")}: 'items' contains duplicates\n" do
    JDL.attr "test_choice_attribute|b", type: :choice do
      items [:a, :a, :b, :b] # 234928DC
    end
  end
end

jtest "requires default to be in items" do
  assert_jaba_error "Error at #{src_loc("8D88FA0D")}: 'c' attribute invalid: 'default' invalid: Must be one of [1, 2, 3] but got '4'." do
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
=begin
jtest 'rejects invalid choices' do
  assert_jaba_error "Error at #{src_loc('21E33D49')}: 't.a' attribute invalid: Must be one of [:a, :b, :c] but got ':d'. See #{src_loc('F0E843B4')}." do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :choice do
          items [:a, :b, :c] # F0E843B4
        end
      end
      test :t do
        a :d # 21E33D49
      end
    end
  end
  assert_jaba_error "Error at #{src_loc('E22800D3')}: 't.a' array attribute invalid: Must be one of [:a, :b, :c] but got ':d'. See #{src_loc('5D58D438')}." do
    jaba(barebones: true) do
      type :test do
        attr_array :a, type: :choice do
          items [:a, :b, :c] # 5D58D438
        end
      end
      test :t do
        a [:a, :b, :c, :d] # E22800D3
      end
    end
  end
end
=end
jtest "can be set from global attrs" do
  JDL.attr "tca_CA9D4D22", type: :choice do
    items [:a, :b, :c]
    default :a
  end
  JDL.attr "tca_06FE9AE2", type: :choice do
    items [:a, :b, :c, nil]
    default :a
  end
  JDL.attr "tca_5A292247", type: :choice do
    items [1, :a, "b"]
    default "b"
  end
  jaba(global_attrs: { 'tca_CA9D4D22': "b", 'tca_06FE9AE2': "", 'tca_5A292247': "1" }) do
    tca_CA9D4D22.must_equal :b
    tca_06FE9AE2.must_be_nil
    tca_5A292247.must_equal 1
  end

  op = jaba(global_attrs: { 'tca_CA9D4D22': "d" }, want_exceptions: false)
  op[:error].must_equal "Error: 'd' invalid value for 'tca_CA9D4D22' attribute - [a|b|c] expected."

  JDL.undefine_attr("tca_CA9D4D22")
  JDL.undefine_attr("tca_06FE9AE2")
  JDL.undefine_attr("tca_5A292247")
end
