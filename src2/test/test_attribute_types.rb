# TODO: should get this dynamically
ATTR_TYPES = [:basename, :bool, :choice, :compound, :dir, :ext, :file, :int, :src, :string, :to_s, :uuid]

jtest "fails if value not supplied when flagged with :required" do
  # Test required top level attr
  ATTR_TYPES.each do |at|
    jdl do
      attr :top, type: at do
        flags :required
        if at == :choice
          items [:a, :b, :c]
        end
      end
    end
    assert_jaba_error "Error at #{src_loc("D43F2208")}: 'top_level' requires 'top' attribute to be set.", hint: at do
      jaba do end # D43F2208
    end
    # Also test file version
    assert_jaba_file_error "'top_level' requires 'top' attribute to be set.", "8CF3DCA2", hint: at do
      "# 8CF3DCA2"
    end
  end

  # Now test required node attr
  ATTR_TYPES.each do |at|
    jdl do
      node :node
      attr "node/a", type: at do
        flags :required
        if at == :choice
          items [:a, :b, :c]
        end
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
