# TODO: validate key type is of specfied key_type
=begin
jtest "supports a default" do
  jaba(barebones: true) do
    type :test do
      attr :single1 do
        default 1
      end
      attr :single2
      attr_hash :a, key_type: :symbol do
        flag_options :opt1, :opt2
      end
      attr_hash :b, key_type: :symbol do
        default({ k: :v }) # value style default
        flag_options :opt1, :opt2
        value_option :vopt
      end
      attr_hash :c, key_type: :symbol do
        default do # block style default
          { k1: 1, k2: 2 }
        end
        flag_options :opt1, :opt2
      end
      attr_hash :d, key_type: :symbol do
        default do # block style default that references other attributes
          { k1: single1, k2: single2 }
        end
        flag_options :opt1, :opt2
      end
    end
    test :t do
      a.must_equal({})

      b[:k].must_equal(:v)
      b.must_equal({ k: :v })

      c.must_equal({ k1: 1, k2: 2 })

      single2 2
      d.must_equal({ k1: 1, k2: 2 })

      # test that defaults can be overridden
      #
      single1 3
      single1.must_equal(3)

      a :k, :v, :opt1
      a.must_equal({ k: :v })

      b :k, :v3, :opt1 # keep same key but overwrite value
      b :k2, :v2, :opt1, vopt: 1
      b :k3, :v3, :opt2
      b.must_equal({ k: :v3, k2: :v2, k3: :v3 }) # New key value gets merged in with default

      c :k3, :v3, :opt1
      c :k4, :v4, :opt2
      c.must_equal({ k1: 1, k2: 2, k3: :v3, k4: :v4 }) # New key value gets merged in with default when block form used

      d :k3, :v3, :opt2
      d :k4, :v4, :opt1
      d.must_equal({ k1: 3, k2: 2, k3: :v3, k4: :v4 })
      generate do
        a = get_attr(:a)
        a.fetch(:k).has_flag_option?(:opt1).must_equal(true)
        b = get_attr(:b)
        b.fetch(:k).has_flag_option?(:opt1).must_equal(true)
        b.fetch(:k2).has_flag_option?(:opt1).must_equal(true)
        b.fetch(:k2).get_option_value(:vopt).must_equal(1)
        b.fetch(:k3).has_flag_option?(:opt2).must_equal(true)
        c = get_attr(:c)
        c.fetch(:k1).has_flag_option?(:opt1).must_equal(true)
        c.fetch(:k2).has_flag_option?(:opt1).must_equal(true)
        c.fetch(:k3).has_flag_option?(:opt1).must_equal(true)
        c.fetch(:k4).has_flag_option?(:opt2).must_equal(true)
        d = get_attr(:d)
        d.fetch(:k1).has_flag_option?(:opt2).must_equal(true)
        d.fetch(:k2).has_flag_option?(:opt2).must_equal(true)
        d.fetch(:k3).has_flag_option?(:opt2).must_equal(true)
        d.fetch(:k4).has_flag_option?(:opt1).must_equal(true)
      end
    end
  end

  # validates that default is a hash
  #
  assert_jaba_error "Error at #{src_loc("DA7750A0")}: 'default' expects a hash but got '[]'." do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol do
          default [] # DA7750A0
        end
      end
    end
  end

  # It validates default is a hash when block form is used
  #
  assert_jaba_error "Error at #{src_loc("BE9F9661")}: 't.a' hash attribute default requires a hash not a 'Integer'." do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol do # BE9F9661
          default do
            1
          end
        end
      end
      test :t # need an instance of test in order for block style defaults to be called
    end
  end

  # It validates default elements respect attribute type
  #
  assert_jaba_error "Error at #{src_loc("251B0D72")}: ':a' hash attribute default invalid: 'not a symbol' is a string - expected a symbol." do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol, type: :symbol do
          default({ k: "not a symbol" }) # 251B0D72
        end
      end
    end
  end

  # TODO: validate key format
  # It validates default elements respect attribute type when block form used
  #
  assert_jaba_error "Error at #{src_loc("BD581364")}: 't.a' hash attribute invalid: 'not a symbol' is a string - expected a symbol." do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol, type: :symbol do # BD581364
          default do
            { k: "not a symbol" }
          end
        end
      end
      test :t # need an intance of test in order for block style defaults to be called
    end
  end
end

jtest "checks for accessing uninitialised attributes" do
  # test with hash attr default using an unset attr
  #
  assert_jaba_error "Error at #{src_loc("6E82E6E7")}: Cannot read uninitialised 't.b' attribute - it might need a default value.", trace: [__FILE__, "4E88B4A0"] do
    jaba(barebones: true) do
      type :test do
        attr :a
        attr :b
        attr_hash :c, key_type: :symbol do
          default do
            { k1: a, k2: b } # 6E82E6E7
          end
        end
      end
      test :t do
        a 1
        c # 4E88B4A0
      end
    end
  end

  # test with another attr using unset hash attr
  #
  assert_jaba_error "Error at #{src_loc("CE4EB215")}: Cannot read uninitialised 't.a' hash attribute - it might need a default value.", trace: [__FILE__, "AA737C96"] do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol
        attr :b do
          default do
            a[:k] # CE4EB215
          end
        end
      end
      test :t do
        b # AA737C96
      end
    end
  end
end
=end

jtest "can be set" do
  JDL.node "tha_252A1CCB"
  JDL.attr_hash "tha_252A1CCB|a"
  JDL.attr "tha_252A1CCB|b", type: :choice do
    items [1, 2]
  end
  jaba do
    tha_252A1CCB :t do
      # Test basic set
      a :k, :v
      a[:k].must_equal(:v)

      # Overwrite value
      a :k, nil
      a[:k].must_be_nil

      # Overwrite back to original
      a :k, :v
      a[:k].must_equal(:v)

      # Add key
      a :k2, :v2
      a[:k2].must_equal(:v2)

      # Value can be set in block
      #
      b 1
      a :key do
        case b
        when 1
          :yes
        else
          :no
        end
      end
      a[:key].must_equal :yes
      b 2
      a :key do
        case b
        when 1
          :yes
        else
          :no
        end
      end
      a[:key].must_equal :no
    end
  end
end

jtest "is not possible to modify returned hash" do
  JDL.node "tah_78CC6AD0"
  JDL.attr_hash "tah_78CC6AD0|a" do
    default({ k: :v })
  end
  assert_jaba_error "Error at #{src_loc("F788FD64")}: Can't modify read only Hash." do
    jaba do
      tah_78CC6AD0 :t do
        a[:k] = :v2 # F788FD64
      end
    end
  end
end
=begin
jtest "disallows no_sort flag" do
  assert_jaba_error "Error at #{src_loc("366C343A")}: :no_sort attribute definition flag is only allowed on array attributes." do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol do
          flags :no_sort # 366C343A
        end
      end
    end
  end
end

jtest "disallows allow_dupes flag" do
  assert_jaba_error "Error at #{src_loc("2E453551")}: :allow_dupes attribute definition flag is only allowed on array attributes." do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol do
          flags :allow_dupes # 2E453551
        end
      end
    end
  end
end

jtest "can accept flag options" do
  jaba(barebones: true) do
    type :test do
      attr_hash :a, key_type: :symbol do
        flag_options :f1, :f2, :f3
      end
    end
    test :t do
      a :k, :v, :f1, :f2
      generate do
        a = get_attr(:a)
        elem = a.fetch(:k)
        elem.value.must_equal(:v)
        elem.has_flag_option?(:f1).must_equal(true)
        elem.has_flag_option?(:f2).must_equal(true)
        elem.has_flag_option?(:f3).must_equal(false)
        elem.flag_options.must_equal [:f1, :f2]
      end
    end
  end
end

jtest "can accept value options" do
  jaba(barebones: true) do
    type :test do
      attr_hash :a, key_type: :symbol do
        value_option :kv1
        value_option :kv2
      end
    end
    test :t do
      a :k, :v, kv1: "a", kv2: "b"
      generate do
        a = get_attr(:a)
        elem = a.fetch(:k)
        elem.value.must_equal(:v)
        elem.get_option_value(:kv1).must_equal("a")
        elem.get_option_value(:kv2).must_equal("b")
      end
    end
  end
end

jtest "can accept value and flag options" do
  jaba(barebones: true) do
    type :test do
      attr_hash :a, key_type: :symbol do
        value_option :kv1
        value_option :kv2
        flag_options [:flag_opt1, :flag_opt2, :flag_opt3]
      end
    end
    test :t do
      a :k, :v, :flag_opt1, :flag_opt2, kv1: "a", kv2: "b"
      generate do
        a = get_attr(:a)
        elem = a.fetch(:k)
        elem.value.must_equal(:v)
        elem.has_flag_option?(:flag_opt1).must_equal(true)
        elem.has_flag_option?(:flag_opt2).must_equal(true)
        elem.has_flag_option?(:flag_opt3).must_equal(false)
        elem.flag_options.must_equal [:flag_opt1, :flag_opt2]
        elem.get_option_value(:kv1).must_equal("a")
        elem.get_option_value(:kv2).must_equal("b")
      end
    end
  end
end

jtest "validates key value supplied correctly" do
  assert_jaba_error "Error at #{src_loc("E4932204")}: 't.a' hash attribute requires a key/value eg \"a :my_key, 'my value'\"" do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol
      end
      test :t do
        a key: "val" # E4932204
      end
    end
  end
  assert_jaba_error "Error at #{src_loc("C567DBCD")}: 't.a' hash attribute requires a key/value eg \"a :my_key, 'my value'\"" do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol
      end
      test :t do
        a :key # C567DBCD
      end
    end
  end
end

jtest "supports setting a validator" do
  # only hash attr has validate_key property
  assert_jaba_error "Error at #{src_loc("95BFB40C")}: 'validate_key' property undefined." do
    jaba(barebones: true) do
      type :test do
        attr_array :a do
          validate_key do |key| # 95BFB40C
          end
        end
      end
    end
  end
  assert_jaba_error "Error at #{src_loc("52EE0D37")}: 't.a' hash attribute invalid: failed.", trace: [__FILE__, "51591CF8"] do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :string do
          validate_key do |key|
            if key == "invalid"
              fail "failed" # 52EE0D37
            end
          end
        end
      end
      test :t do
        a "k1", :v
        a "invalid", :v # 51591CF8
      end
    end
  end

  assert_jaba_error "Error at #{src_loc("A01B3D5E")}: 't.a' hash attribute invalid: failed.", trace: [__FILE__, "AC0009E0"] do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol do
          validate do |val|
            if val == "invalid"
              fail "failed" # A01B3D5E
            end
          end
        end
      end
      test :t do
        a :k, :v
        a :k, "invalid" # AC0009E0
      end
    end
  end
end

# TODO: test wipe

jtest "supports on_set hook" do
  jaba(barebones: true) do
    type :test do
      attr_hash :a, key_type: :string do
        # on_set executed in context of node so all attributes available
        on_set do |k, v|
          b "#{k}_b", "#{v}_b"
        end
      end
      attr_hash :b, key_type: :string do
        # new value can be taken from block arg
        on_set do |k, v|
          c "#{k}#{v}"
        end
      end
      attr :c
    end
    test :t do
      a 1, 2
      b.must_equal({ "1_b" => "2_b" })
      c.must_equal "1_b2_b"
    end
  end
end
=end