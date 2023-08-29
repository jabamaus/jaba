jtest 'only accepts single values' do
  assert_jaba_error "Error at #{src_loc('787CC36C')}: 'default' expects a single value but got '[]'." do
    jaba(barebones: true) do
      type :test do
        attr :a do
          default [] # 787CC36C
        end
      end
    end
  end

  assert_jaba_error "Error at #{src_loc('6D4B452C')}: 't.a' attribute must be a single value not a 'Array'." do
    jaba(barebones: true) do
      type :test do
        attr :a
      end
      test :t do
        a [1, 2] # 6D4B452C
      end
    end
  end
end

jtest 'allows setting value with block' do
  jaba(barebones: true) do
    type :test do
      attr :a
      attr :b
    end
    test :t do
      b 1
      a do
        b + 1
      end
      a.must_equal 2
    end
  end
end

jtest 'rejects modifying returned values' do
  assert_jaba_error "Error at #{src_loc('216BACF8')}: Can't modify read only String: \"b\"" do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :string do
          default 'b'
        end
      end
      test :t do
        val = a
        val.upcase! # 216BACF8
        a.must_equal('b')
      end
    end
  end
  assert_jaba_error "Error at #{src_loc('45925C07')}: Can't modify read only String: \"b\"" do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :string do
        end
      end
      test :t do
        a 'b'
        val = a
        val.upcase! # 45925C07
      end
    end
  end
end

jtest 'rejects modifying read only attributes' do
  assert_jaba_error "Error at #{src_loc('D4AE68B1')}: 't.a' attribute is read only." do
    jaba(barebones: true) do
      type :test do
        attr :a do
          flags :read_only
          default 1
        end
      end
      test :t do
        a.must_equal(1)
        a 2 # D4AE68B1
      end
    end
  end

  assert_jaba_error "Error at #{src_loc('E1EF7425')}: 't.a' attribute is read only." do
    jaba(barebones: true) do
      type :test do
        attr :a do
          flags :read_only
        end
      end
      test :t do
        a 1 # E1EF7425
      end
    end
  end
end

jtest 'works with block style default' do
  jaba(barebones: true) do
    type :test do
      attr :a
      attr :b
      attr :c do
        default do
          "#{a}_#{b}"
        end
      end
    end
    test :t do
      a 1
      b 2
      c.must_equal '1_2'
    end
  end

  # test with attr default using an unset attr
  #
  assert_jaba_error "Error at #{src_loc('4993BD24')}: Cannot read uninitialised 't.b' array attribute - it might need a default value.", trace: [__FILE__, '2F003EB7'] do
    jaba(barebones: true) do
      type :test do
        attr :a
        attr_array :b
        attr :c do
          default do
            "#{a}_#{b.size}" # 4993BD24
          end
        end
      end
      test :t do
        a 1
        c # 2F003EB7
      end
    end
  end

  # test with another attr using unset attr
  #
  assert_jaba_error "Error at #{src_loc('4F004E26')}: Cannot read uninitialised 't.a' attribute - it might need a default value.", trace: [__FILE__, 'A0C828F8'] do
    jaba(barebones: true) do
      type :test do
        attr :a
        attr_array :b do
          default do
            [a] # 4F004E26
          end
        end
      end
      test :t do
        b # A0C828F8
      end
    end
  end
end

jtest 'fails if default block sets attribute' do
  assert_jaba_error "Error at #{src_loc('218296F2')}: 't.a' attribute is read only in this context." do
    jaba(barebones: true) do
      type :test do
        attr :a
        attr :b do
          default do
            a 1 # 218296F2
          end
        end
      end
      test :t do
      end
    end
  end
end

jtest 'validates flag options' do
  assert_jaba_error "Error at #{src_loc('0BE71C6C')}: Invalid flag option ':d' passed to 't.a' attribute. Valid flags are [:a, :b, :c]" do
    jaba(barebones: true) do
      type :test do
        attr :a do
          flag_options :a, :b, :c
        end
      end
      test :t do
        a 1, :a, :b, :d # 0BE71C6C
      end
    end
  end
end

jtest 'overwrites flag and keyval options on successive calls' do
  jaba(barebones: true) do
    type :test do
      attr :a do
        flag_options :fo1, :fo2, :fo3
        value_option :kv1
        value_option :kv2
        value_option :kv3
      end
    end
    test :t do
      a 1, :fo1, kv1: 2
      a 2, :fo2, :fo3, kv2: 3, kv3: 4
      generate do
        a = get_attr(:a)
        a.has_flag_option?(:fo1).must_equal(false)
        a.has_flag_option?(:fo2).must_equal(true)
        a.has_flag_option?(:fo3).must_equal(true)
        a.get_option_value(:kv1, fail_if_not_found: false).must_be_nil
        a.get_option_value(:kv2).must_equal(3)
        a.get_option_value(:kv3).must_equal(4)
      end
    end
  end
end

# TODO: check wiping down required values
jtest 'supports wiping value back to default' do
  jaba(barebones: true) do
    type :test do
      attr :a do
        default 1
      end
      attr :b do
        default 'b'
      end
      attr :c do
        default :c
      end
      attr :d do
        default nil
      end
    end
    test :t do
      a.must_equal(1)
      a 2
      a.must_equal(2)
      b.must_equal('b')
      b 'bb'
      c.must_equal(:c)
      c :cc
      d.must_be_nil
      d 'd'
      d.must_equal('d')
      wipe :a
      wipe :b, :c, :d
      a.must_equal(1)
      b.must_equal('b')
      c.must_equal(:c)
      d.must_be_nil
    end
  end
end

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
