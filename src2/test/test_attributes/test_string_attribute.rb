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

=begin
jtest "accepts symbols" do
  jdl do
    attr :a, type: :string
  end
  jaba do
    a :b
    a.must
end
=end

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
    attr :a, type: :string do default "a" end
    attr :b, type: :string
  end
  output = jaba(global_attrs_from_cmdline: { "a": "b", "b": "c" }) do
    a.must_equal "b"
    b.must_equal "c"
  end

  root = output[:root]
  root[:a].must_equal "b"
  root[:b].must_equal "c"
end
