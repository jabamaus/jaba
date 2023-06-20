jtest "only accepts single values" do
  jdl do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("787CC36C")}: 'a' attribute invalid - 'default' expects a single value but got '[]'." do
      attr :a do
        default [] # 787CC36C
      end
    end
    attr :b
  end

  assert_jaba_error "Error at #{src_loc("6D4B452C")}: 'b' attribute invalid - must be a single value not a 'Array'." do
    jaba do
      b [1, 2] # 6D4B452C
    end
  end
end

jtest "allows setting value with block" do
  jdl do
    attr :a
    attr :b
  end
  jaba do
    b 1
    a do
      b + 1
    end
    a.must_equal 2
  end
end

jtest "rejects modifying returned values" do
  jdl do
    attr :a
    attr :b do
      default "b"
    end
    attr :c do
      default do
        "d"
      end
    end
  end
  assert_jaba_error "Error at #{src_loc("45925C07")}: Can't modify read only String." do
    jaba do
      a "b"
      a.upcase! # 45925C07
    end
  end
  assert_jaba_error "Error at #{src_loc("DAFA4190")}: Can't modify read only String." do
    jaba do
      b.upcase! # DAFA4190
    end
  end
  assert_jaba_error "Error at #{src_loc("BE7A76FA")}: Can't modify read only String." do
    jaba do
      c.upcase! # BE7A76FA
    end
  end
end

jtest "supports default value" do
  jdl do
    attr :a
    attr :b
    attr :c do
      default do
        "#{a}_#{b}"
      end
    end
    attr :d do
      default do
        c
      end
    end
    attr :e, type: :uuid do
      default do
        c
      end
    end
  end
  op = jaba do
    a 1
    b 2
    c.must_equal "1_2"
  end
  r = op[:root]
  r[:a].must_equal 1
  r[:b].must_equal 2
  r[:c].must_equal "1_2"
  r[:d].must_equal "1_2"
  r[:e].must_equal "{3BD8F1BB-E5D7-5F5F-BC5D-6451E9D05F0E}" # e is not set but default should still be mapped to a uuid

  # test with attr default using an unset attr
  assert_jaba_error "Error at #{src_loc("2F003EB7")}: 'c' attribute default read uninitialised 'b' attribute - it might need a default value." do
    jaba do
      a 1
      c # 2F003EB7
    end
  end

  # test with another attr using unset attr
  assert_jaba_error "Error at #{src_loc("A0C828F8")}: 'd' attribute default read uninitialised 'a' attribute - it might need a default value." do
    jaba do
      b 1
      d # A0C828F8
    end
  end
end

jtest "fails if default block sets attribute" do
  jdl do
    attr :a
    attr :b do
      default do
        a 1 # 218296F2
      end
    end
  end
  assert_jaba_error "Error at #{src_loc("218296F2")}: 'a' attribute is read only in this scope." do
    jaba do
      b
    end
  end
end

jtest "supports flag options" do
  jdl do
    attr :a do
      flag_options :a, :b, :c
    end
  end
  op = jaba do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("0BE71C6C")}: Invalid flag option ':d' passed to 'a' attribute. Valid flags are [:a, :b, :c]" do
      a 1, :d # 0BE71C6C
    end
    a 1, :a
    a 2, :b # flags are additive even if value different
    a 2, :a # F5A83F4D duplicate flag should produce warning
  end
  op[:warnings].must_equal ["Warning at #{src_loc("F5A83F4D")}: 'a' attribute was passed duplicate flag ':a'."]
  a = op[:root].get_attr(:a)
  a.value.must_equal 2
  a.flag_options.must_equal [:a, :b]
end

jtest "supports value options" do
  jdl do
    attr :a do
      option :opt_single, type: :int
      option :opt_array, variant: :array
      option :opt_single_choice, type: :choice do
        items [:a, :b, :c]
      end
    end
    attr :b do
      option :opt_single, type: :int
      option :opt_array, variant: :array
    end
  end
  op = jaba do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("FA31131B")}: 'a' attribute does not support ':opt_invalid' option." do
      a 1, opt_invalid: 2 # FA31131B
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("518BF756")}: 'opt_single' attribute invalid - 'not an int' is a string - expected an integer." do
      a 1, opt_single: "not an int" # 518BF756
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("C044A39E")}: 'opt_single_choice' attribute invalid - must be one of [:a, :b, :c] but got ':d'." do
      a 1, opt_single_choice: :d # C044A39E
    end
    a 1, opt_single: 1, opt_array: [2, 3], opt_single_choice: :b

    # Calling again with same value will cause opt_single to be overwritten and opt_arrray to be extended
    a 1, opt_single: 5, opt_array: [6, 7], opt_single_choice: :c

    # value options are additive even if value changes
    b 8, opt_single: 9, opt_array: [10, 11]
    b 12, opt_array: [13, 14]
  end
  a = op[:root].get_attr(:a)
  a.value.must_equal 1
  a.option_value(:opt_single).must_equal 5
  a.option_value("opt_single").must_equal 5
  a.option_value(:opt_single_choice).must_equal :c
  a.option_value(:opt_array).must_equal [2, 3, 6, 7]

  b = op[:root].get_attr(:b)
  b.value.must_equal 12
  b.option_value(:opt_single).must_equal 9
  b.option_value(:opt_array).must_equal [10, 11, 13, 14]
end

# TODO: test on_set in conjunction with exporting
jtest "supports on_set hook" do
  jdl do
    attr :a do
      # on_set executed in context of node so all attributes available
      on_set do
        b "#{a}_b"
      end
    end
    attr :b do
      # new value can be taken from block arg
      on_set do |new_val|
        c "#{new_val}_c"
      end
    end
    attr :c
    attr :d do
      on_set do |val|
        e "#{val}_b"
      end
    end
    attr :e do
      on_set do |val|
        d "#{val}_a" # EF4427A6
      end
    end
  end
  jaba do
    a 1
    b.must_equal("1_b")
    c.must_equal("1_b_c")
    JTest.assert_jaba_error "Error at #{JTest.src_loc("EF4427A6")}: Reentrancy detected in 'd' attribute on_set." do
      d 1
    end
  end
end
