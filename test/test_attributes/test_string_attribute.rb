jtest "validates default" do
  jdl do
    attr :a, type: :string do
      default 1 # 4847EA74
    end
  end
  assert_jaba_error "Error at #{src_loc("4847EA74")}: 'a' attribute invalid - 'default' invalid - '1' is a integer - expected a string or symbol." do
    jaba do end
  end
end

jtest "interopates with symbols" do
  jdl do
    attr :a, type: :string
    attr :b, variant: :array, type: :string
    attr :c, variant: :hash, type: :string do
      key_type :string
    end
  end
  jaba do
    a :b
    a.must_equal "b" # Set as a symbol but stored as string
    a.class.must_equal JABA::JABAString
    b [:c, :d, "e"]
    b.must_equal ["c", "d", "e"]
    c :a, :b
    c.must_equal({ "a": "b" })
    (a == :b).must_be_true #  JABAString allows comparison with symbols
    match = false
    case a
    when :b
      match = true
    end
    match.must_be_true
  end
end

jtest "supports standard ops" do
  jdl do
    attr :a, type: :string
    attr :b, variant: :array, type: :string
    attr :c, variant: :hash, type: :string do
      key_type :string
    end
  end
  jaba do
    b [:a, :b, :c, :d], exclude: [:b, :d]
    b.must_equal ["a", "c"]
  end
end

jtest "can default to id" do
  jdl(level: :core) do
    node :node
    attr "node/a", type: :string do
      default do
        id
      end
    end
  end
  jaba do
    node :n do
      a.must_equal "n"
    end
  end
end

jtest "cannot be set to nil" do
  jdl do
    attr :a, type: :string
  end
  jaba do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("77EE98F7")}: 'a' attribute invalid - 'nil' is invalid - expected a string or symbol." do
      a nil # 77EE98F7
    end
  end
end

jtest "can be set from cmdline" do
  jdl do
    attr :a, type: :string
    attr :b, variant: :array, type: :string
    attr :c, variant: :hash, type: :string do
      key_type :string
    end
  end
  jaba(global_attrs_from_cmdline: { "a": "b", "b": ["c", "d"], "c": ["e", "f", "g", "h"] }) do
    a.must_equal "b"
    b.must_equal ["c", "d"]
    c.must_equal({ "e" => "f", "g" => "h" })
  end
end
