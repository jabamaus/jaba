JDL.node "taa1"
JDL.node "taa2"
JDL.node "taa3"
JDL.node "taa4"

jtest "supports a default" do
  # It validates default is an array or single value
  #
  assert_jaba_error "Error at #{src_loc("C3E1CABD")}: 'invalid_default' array attribute invalid: 'default' expects an array but got '{:a=>:b}'." do
    JDL.attr_array "taa1|invalid_default" do
      default({ a: :b }) # C3E1CABD
    end
  end

  # It validates default is an array when block form is used
  #
  assert_jaba_error "Error at #{src_loc("9F62104F")}: 't.invalid_default_block' array attribute 'default' invalid: requires an array not a 'Integer'." do
    JDL.attr_array "taa1|invalid_default_block" do
      default do # 9F62104F
        1
      end
    end
    jaba do
      taa1 :t # need an instance of test in order for block style defaults to be called
    end
  end

  # It validates default elements respect attribute type
  #
  assert_jaba_error "Error at #{src_loc("7F5657F4")}: 'invalid_default_elem' array attribute invalid: 'default' invalid: 'not a bool' is a string - expected [true|false]" do
    JDL.attr_array "taa2|invalid_default_elem", type: :bool do
      default ["not a bool"] # 7F5657F4
    end
  end

  # It validates default elements respect attribute type when block form used
  #
  assert_jaba_error "Error at #{src_loc("33EF0612")}: 't.invalid_default_elem_with_block' array attribute 'default' invalid: 'not a bool' is a string - expected [true|false]" do
    JDL.attr_array "taa3|invalid_default_elem_with_block", type: :bool do # 33EF0612
      default do
        ["not a bool"]
      end
    end
    jaba do
      taa3 :t # need an instance of test in order for block style defaults to be called
    end
  end
  # TODO: test flag/value options
  JDL.attr_array "taa4|a"
  JDL.attr_array "taa4|b" do
    default [1, 2, 3] # value style default
  end
  JDL.attr_array "taa4|c" do
    default do # block style default
      [4, 5, 6]
    end
  end
  JDL.attr_array "taa4|d" do
    default do # block style default referencing other attrs
      b + c
    end
  end
  JDL.attr_array "taa4|e" do
    default [7, 8]
  end

  jaba do
    taa4 :t do
      a.must_equal [] # defaults to empty array
      b.must_equal [1, 2, 3]
      c.must_equal [4, 5, 6]
      d.must_equal [1, 2, 3, 4, 5, 6]
      d [7, 8] # default array values are appended to not overwritten when block style used
      d 9
      d.must_equal [1, 2, 3, 4, 5, 6, 7, 8, 9]
      e [9] # default array values are appended to not overwritten when value style used
      e.must_equal [7, 8, 9]
    end
  end
end
