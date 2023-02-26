JDL.node "test_attribute_array"

jtest "supports a default" do
  # It validates default is an array or single value
  #
  assert_jaba_error "Error at #{src_loc("C3E1CABD")}: 'invalid_default' array attribute invalid: 'default' expects an array but got '{:a=>:b}'.", ignore_trace: true do
    JDL.attr_array "test_attribute_array|invalid_default" do
      default({ a: :b }) # C3E1CABD
    end
  end

  # It validates default is an array when block form is used
  #
  assert_jaba_error "Error at #{src_loc("9F62104F")}: 't.invalid_default_block' array attribute default requires an array not a 'Integer'." do
    JDL.attr_array "test_attribute_array|invalid_default_block" do
      default do # 9F62104F
        1
      end
    end
    jaba do
      test_attribute_array :t # need an instance of test in order for block style defaults to be called
    end
  end
=begin
  # It validates default elements respect attribute type
  #
  assert_jaba_error "Error at #{src_loc('7F5657F4')}: ':a' array attribute default invalid: 'not a symbol' is a string - expected a symbol." do
    jaba(barebones: true) do
      type :test do
        attr_array :a, type: :symbol do
          default ['not a symbol'] # 7F5657F4
        end
      end
    end
  end

  # It validates default elements respect attribute type when block form used
  #
  assert_jaba_error "Error at #{src_loc('33EF0612')}: 't.a' array attribute invalid: 'not a symbol' is a string - expected a symbol." do
    jaba(barebones: true) do
      type :test do
        attr_array :a, type: :symbol do # 33EF0612
          default do
            ['not a symbol']
          end
        end
      end
      test :t # need an instance of test in order for block style defaults to be called
    end
  end

  # TODO: test flag/value options
  jaba(barebones: true) do
    type :test do
      attr_array :a
      attr_array :b do
        default [1, 2, 3] # value style default
      end
      attr_array :c do
        default do # block style default
          [4, 5, 6]
        end
      end
      attr_array :d do
        default do # block style default referencing other attrs
          b + c
        end
      end
      attr_array :e do
        default [7, 8]
      end
    end
    test :t do
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
=end
end
