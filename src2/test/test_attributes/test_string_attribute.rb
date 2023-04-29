jtest "validates default" do
  jdl do
    attr :a, type: :string do
      default 1 # 4847EA74
    end
  end
  assert_jaba_error "Error at #{src_loc("4847EA74")}: 'a' attribute invalid - 'default' invalid - '1' is a integer - expected a string." do
    jaba
  end
end

jtest "accepts symbols but stored as strings" do
  jdl do
    attr :a, type: :string
    attr_array :b, type: :string
    attr_hash :c, key_type: :string, type: :string
  end
  jaba do
    a :b
    a.must_equal "b"
    b [:c, :d, "e"]
    b.must_equal ["c", "d", "e"]
    c :a, :b
    c.must_equal({"a": "b"})
  end
end

# TODO: add support for id attribute as a node option
=begin
jtest "can default to id" do
  jdl do
    node :node
    attr "node|a", type: :string do
      default do
        id.to_s
      end
    end
  end
  jaba do
    node :n do
      a.must_equal "n"
    end
  end
end
=end

jtest "can be set from cmdline" do
  jdl do
    attr :a, type: :string
    attr_array :b, type: :string
    attr_hash :c, key_type: :string, type: :string
  end
  jaba(global_attrs_from_cmdline: { "a": "b", "b": ["c", "d"], "c": ["e", "f", "g", "h"] }) do
    a.must_equal "b"
    b.must_equal ["c", "d"]
    c.must_equal({"e" => "f", "g" => "h"})
  end
end
