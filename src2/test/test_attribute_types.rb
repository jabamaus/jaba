# TODO: should get this dynamically
ATTR_VARIANTS = [:single, :array, :hash]
ATTR_TYPES = {
  basename: "basename",
  bool: false,
  choice: :a,
  compound: nil,
  dir: "dir",
  ext: ".ext",
  file: "file",
  int: 1,
  src: "src",
  string: "string",
  to_s: "to_s",
  uuid: "uuid",
}

def each_attr
  ATTR_VARIANTS.each do |av|
    ATTR_TYPES.each do |at, default|
      yield av, at, "(#{at} #{av})", default
    end
  end
end

jtest "fails if value not supplied when flagged with :required" do
  # Test required top level attr
  each_attr do |av, at, desc|
    jdl do
      attr :a, variant: av, type: at do
        flags :required
        key_type :string if av == :hash
        items [:a, :b, :c] if at == :choice
      end
    end
    assert_jaba_error "Error at #{src_loc("D43F2208")}: 'top_level' requires 'a' attribute to be set.", hint: desc do
      jaba do end # D43F2208
    end
    assert_jaba_file_error "'top_level' requires 'a' attribute to be set.", "8CF3DCA2", hint: desc do
      "# 8CF3DCA2"
    end
  end

  # Now test required node attr
  each_attr do |av, at, desc|
    jdl do
      node :node
      attr "node/a", variant: av, type: at do
        flags :required
        key_type :string if av == :hash
        items [:a, :b, :c] if at == :choice
      end
    end

    assert_jaba_error "Error at #{src_loc("BAD8B7FA")}: 'node' requires 'a' attribute to be set.", hint: at do
      jaba do
        node :n # BAD8B7FA
      end
    end
    assert_jaba_file_error "'node' requires 'a' attribute to be set.", "3C869B0D" do
      "node :n # 3C869B0D"
    end
  end
end
=begin
jtest "rejects modifying read only attributes" do
  each_attr do |av, at, desc, default_|
    jdl do
      attr :a, variant: av, type: at do
        flags :read_only
        items [:a, :b, :c] if at == :choice
        key_type :string if av == :hash
        #default default_ 
      end
    end
    jaba do
      JTest.assert_jaba_error "Error at #{JTest.src_loc("D4AE68B1")}: 'a' attribute is read only.", hint: desc do
        a default_ # D4AE68B1
      end
    end
  end
end
=end