jtest "supports a default" do
  # It validates default is an array or single value
  #
  JDL.node "taa_FDBC8D07"
  assert_jaba_error "Error at #{src_loc("C3E1CABD")}: 'a' array attribute invalid: 'default' expects an array but got '{:a=>:b}'." do
    JDL.attr_array "taa_FDBC8D07|a" do
      default({ a: :b }) # C3E1CABD
    end
  end

  # It validates default is an array when block form is used
  #
  assert_jaba_error "Error at #{src_loc("9F62104F")}: 't.a' array attribute 'default' invalid: requires an array not a 'Integer'." do
    JDL.attr_array "taa_FDBC8D07|a" do
      default do # 9F62104F
        1
      end
    end
    jaba do
      taa_FDBC8D07 :t # need an instance of test in order for block style defaults to be called
    end
  end

  # It validates default elements respect attribute type
  #
  JDL.node "taa_31B41D7D"
  assert_jaba_error "Error at #{src_loc("7F5657F4")}: 'a' array attribute invalid: 'default' invalid: 'not a bool' is a string - expected [true|false]" do
    JDL.attr_array "taa_31B41D7D|a", type: :bool do
      default ["not a bool"] # 7F5657F4
    end
  end

  # It validates default elements respect attribute type when block form used
  #
  JDL.node "taa_B62CF7DA"
  assert_jaba_error "Error at #{src_loc("33EF0612")}: 't.a' array attribute 'default' invalid: 'not a bool' is a string - expected [true|false]" do
    JDL.attr_array "taa_B62CF7DA|a", type: :bool do # 33EF0612
      default do
        ["not a bool"]
      end
    end
    jaba do
      taa_B62CF7DA :t # need an instance of test in order for block style defaults to be called
    end
  end

  JDL.node "taa_A9DB2DFF"
  JDL.attr_array "taa_A9DB2DFF|a"
  JDL.attr_array "taa_A9DB2DFF|b" do
    default [1, 2, 3] # value style default
  end
  JDL.attr_array "taa_A9DB2DFF|c" do
    default do # block style default
      [4, 5, 6]
    end
  end
  JDL.attr_array "taa_A9DB2DFF|d" do
    default do # block style default referencing other attrs
      b + c
    end
  end
  JDL.attr_array "taa_A9DB2DFF|e" do
    default [7, 8]
  end

  jaba do
    taa_A9DB2DFF :t do
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

=begin
jtest 'checks for accessing uninitialised attributes' do
  # test with array attr default using an unset attr
  #
  assert_jaba_error "Error at #{src_loc('C5ADC065')}: Cannot read uninitialised 't.b' attribute - it might need a default value.", trace: [__FILE__, '9BCB5240'] do
    jaba(barebones: true) do
      type :test do
        attr :a
        attr :b
        attr_array :c do
          default do
            [a, b] # C5ADC065
          end
        end
      end
      test :t do
        a 1
        c # 9BCB5240
      end
    end
  end

  # test with another attr using unset array attr
  #
  assert_jaba_error "Error at #{src_loc('5F23FC3F')}: Cannot read uninitialised 't.a' array attribute - it might need a default value.", trace: [__FILE__, '49323AB4'] do
    jaba(barebones: true) do
      type :test do
        attr_array :a
        attr :b do
          default do
            a[0] # 5F23FC3F
          end
        end
      end
      test :t do
        b # 49323AB4
      end
    end
  end
end
=end

jtest "allows setting value with block" do
  JDL.node "taa_AEE0049A"
  JDL.attr_array "taa_AEE0049A|a"
  JDL.attr "taa_AEE0049A|b"
  JDL.attr "taa_AEE0049A|c"
  JDL.attr "taa_AEE0049A|d"
  jaba do
    taa_AEE0049A :t do
      b 1
      c 2
      d 3
      a do
        val = []
        val << b if b < 2
        val << c if c > 3
        val << d if d == 3
        val
      end
      a.must_equal [1, 3]
    end
  end
end

jtest "is not possible to modify returned array" do
  JDL.node "taa_F6D39F9F"
  JDL.attr_array "taa_F6D39F9F|a" do
    default [:a]
  end
  assert_jaba_error "Error at #{src_loc("B50C68BE")}: Can't modify read only Array: [:a]" do
    jaba do
      taa_F6D39F9F :t do
        a << :b # B50C68BE
      end
    end
  end
end

jtest "handles duplicates" do
  JDL.node "taa_A738BF86"
  JDL.attr_array "taa_A738BF86|a" # Duplicates will be stripped by default
  JDL.attr_array "taa_A738BF86|b" do
    flags :allow_dupes
  end
  JDL.attr_array "taa_A738BF86|c", type: :bool
  JDL.attr_array "taa_A738BF86|d"
  assert_jaba_warn("Stripping duplicate '5' from 't.a' array attribute. See previous at test_attribute_array.rb:#{src_line("199488E3")}", __FILE__, "DD827579") do
    jaba do
      taa_A738BF86 :t do
        a [5] # 199488E3
        a [5, 6, 6, 7, 7, 7, 8] # DD827579
        a.must_equal [5, 6, 7, 8]
        b [5, 5, 6, 6, 7, 7, 7] # duplicates allowed
        b.must_equal [5, 5, 6, 6, 7, 7, 7]
        c [true, false, false, true] # Never strips duplicates in bool arrays
        c.must_equal [true, false, false, true]
        d ["aa", "ab", "ac"]
        d ["a", "b", "c"], prefix: "a" # Test duplicates caused by prefix still stripped
        d.must_equal ["aa", "ab", "ac"]
      end
    end
  end
end

jtest "handles sorting" do
  JDL.node "taa_7E3DDF5E"
  JDL.attr_array "taa_7E3DDF5E|a"
  JDL.attr_array "taa_7E3DDF5E|b"
  JDL.attr_array "taa_7E3DDF5E|c"
  JDL.attr_array "taa_7E3DDF5E|d"
  JDL.attr_array "taa_7E3DDF5E|e", type: :bool
  JDL.attr_array "taa_7E3DDF5E|f" do
    flags :no_sort
  end
  op = jaba do
    taa_7E3DDF5E :t do
      a [5, 4, 2, 1, 3]
      a.must_equal [5, 4, 2, 1, 3] # doesn't sort immediately
      b ["e", "c", :a, "a", "A", :C] # sorts case-insensitively
      c [10.34, 3, 800.1, 0.01, -1]
      d [:e, :c, :a, :A, :C]
      e [true, false, false, true] # never sorts a bool array
      f [5, 4, 3, 2, 1]
    end
  end
  t = op[:root].children[0]
  t.get_attr("a").value.must_equal [1, 2, 3, 4, 5]
  t.get_attr("b").value.must_equal [:a, "a", "A", "c", :C, "e"]
  t.get_attr("c").value.must_equal [-1, 0.01, 3, 10.34, 800.1]
  t.get_attr("d").value.must_equal [:a, :A, :c, :C, :e]
  t.get_attr("e").value.must_equal [true, false, false, true]
  t.get_attr("f").value.must_equal [5, 4, 3, 2, 1] # unsorted due to :no_sort
end
