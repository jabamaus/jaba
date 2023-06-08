# TODO: should get this dynamically
ATTR_TYPES = {
  basename: 'basename',
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

jtest "fails if value not supplied when flagged with :required" do
  # Test required top level attr
  ATTR_TYPES.keys.each do |at|
    jdl do
      attr :top_single, type: at do
        flags :required
        items [:a, :b, :c] if at == :choice
      end
      attr :top_array, variant: :array, type: at do
        flags :required
        items [:a, :b, :c] if at == :choice
      end
    end
    assert_jaba_error "Error at #{src_loc("D43F2208")}: 'top_level' requires 'top_single' attribute to be set.", hint: at do
      jaba do end # D43F2208
    end
    assert_jaba_file_error "'top_level' requires 'top_single' attribute to be set.", "8CF3DCA2", hint: at do
      "# 8CF3DCA2"
    end
    assert_jaba_error "Error at #{src_loc("AE95398C")}: 'top_level' requires 'top_array' attribute to be set.", hint: at do
      jaba do end # AE95398C
    end
    assert_jaba_file_error "'top_level' requires 'top_array' attribute to be set.", "9A8716BE", hint: at do
      "# 9A8716BE"
    end
  end

  # Now test required node attr
  ATTR_TYPES.keys.each do |at|
    jdl do
      node :node
      attr "node/a", type: at do
        flags :required
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
  ATTR_TYPES.each do |at, default_|
    jdl do
      attr :single, type: at do
        flags :read_only
        items [:a, :b, :c] if at == :choice
        default default_ if !default_.nil?
      end
      if at == :compound
      end
      attr :array, variant: :array, type: at do
        flags :read_only
        items [:a, :b, :c] if at == :choice
       # default [default_] if !default_.nil?
      end
    end
    jaba do
      JTest.assert_jaba_error "Error at #{JTest.src_loc("D4AE68B1")}: 'single' attribute is read only.", hint: at do
        single default_ # D4AE68B1
      end
      JTest.assert_jaba_error "Error at #{JTest.src_loc("3C528822")}: 'array' attribute element is read only.", hint: at do
        case at
        when :compound
        else
          array default_ # 3C528822
        end
      end
    end
  end
end
=end