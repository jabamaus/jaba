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
  end
  assert_jaba_file_error "Can't modify read only String.", "45925C07" do
    %Q{
  a "b"
  val = a
  val.upcase! # 45925C07
}
  end
end

jtest "rejects modifying read only attributes" do
  jdl do
    attr :a do
      flags :read_only
      default 1
    end
  end
  assert_jaba_file_error "'a' attribute is read only.", "D4AE68B1" do
    %Q{
  a.must_equal(1)
  a 2 # D4AE68B1
}
  end
end

jtest "works with block style default" do
  jdl do
    attr :a
    attr :b
    attr :block_default do
      default do
        "#{a}_#{b}"
      end
    end
    attr :block_default2 do
      default do
        block_default
      end
    end
  end
  jaba do
    a 1
    b 2
    block_default.must_equal "1_2"
  end

  # test with attr default using an unset attr
  assert_jaba_error "Error at #{src_loc("2F003EB7")}: 'block_default' attribute default read uninitialised 'b' attribute - 'b' attribute might need a default value." do
    jaba do
      a 1
      block_default # 2F003EB7
    end
  end

  # test with another attr using unset attr
  assert_jaba_error "Error at #{src_loc("A0C828F8")}: 'block_default2' attribute default read uninitialised 'a' attribute - 'a' attribute might need a default value." do
    jaba do
      b 1
      block_default2 # A0C828F8
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
  assert_jaba_error "Error at #{src_loc("218296F2")}: 'a' attribute is read only in this context." do
    jaba do
      b
    end
  end
end

jtest "validates flag options" do
  jdl do
    attr :a do
      flag_options :a, :b, :c
    end
  end
  assert_jaba_error "Error at #{src_loc("0BE71C6C")}: Invalid flag option ':d' passed to 'a' attribute. Valid flags are [:a, :b, :c]" do
    jaba do
      a 1, :a, :b, :d # 0BE71C6C
    end
  end
end

jtest "overwrites flag and value options on successive calls" do
  jdl do
    attr :a do
      flag_options :fo1, :fo2, :fo3
      value_option :kv1
      value_option :kv2
      value_option :kv3
    end
  end
  op = jaba do
    a 1, :fo1, kv1: 2
    a 2, :fo2, :fo3, kv2: 3, kv3: 4
  end
  a = op[:root].get_attr(:a)
  a.has_flag_option?(:fo1).must_be_false
  a.has_flag_option?(:fo2).must_be_true
  a.has_flag_option?(:fo3).must_be_true
  a.get_option_value(:kv1, fail_if_not_found: false).must_be_nil
  a.get_option_value(:kv2).must_equal(3)
  a.get_option_value(:kv3).must_equal(4)
end

# TODO: port
=begin
# TODO: test on_set in conjunction with exporting
jtest 'supports on_set hook' do
  jaba(barebones: true) do
    type :test do
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
    end
    test :t do
      a 1
      b.must_equal("1_b")
      c.must_equal("1_b_c")
    end
  end
  assert_jaba_error "Error at #{src_loc('EF4427A6')}: Reentrancy detected in 't.a' attribute on_set.", trace: [__FILE__, '6631BC31', __FILE__, 'C16793AE'] do
    jaba(barebones: true) do
      type :test do
        attr :a do
          on_set do
            b "#{a}_b" # 6631BC31
          end
        end
        attr :b do
          on_set do
            a "#{b}_a" # EF4427A6
          end
        end
      end
      test :t do
        a 1 # C16793AE
      end
    end
  end
end
=end
