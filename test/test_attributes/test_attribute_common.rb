module JabaTestMethods
  def coerce_to_variant(variant, val, key)
    case variant
    when :single
      val
    when :array
      [val]
    when :hash
      { key => val }
    end
  end

  def make_args(variant, val, key: :k)
    [coerce_to_variant(variant, val, key)]
  end

  def each_variant(single: true, array: true, hash: true)
    [:single, :array, :hash].each do |av|
      next if av == :single && !single
      next if av == :array && !array
      next if av == :hash && !hash
      yield av, "(#{av})"
    end
  end
end

jtest "fails if value not supplied when flagged with :required" do
  # Test required top level attr
  each_variant do |av, desc|
    jdl do
      attr :a, variant: av, type: :int do
        flags :required
      end
    end
    assert_jaba_error "Error at #{src_loc("D43F2208")}: 'root' requires 'a' attribute to be set.", hint: desc do
      jaba do end # D43F2208
    end
    assert_jaba_file_error "'root' requires 'a' attribute to be set.", "8CF3DCA2", hint: desc do
      "# 8CF3DCA2"
    end
  end

  # Now test required node attr
  each_variant do |av, desc|
    jdl do
      node :node
      attr "node/a", variant: av, type: :int do
        flags :required
      end
    end

    assert_jaba_error "Error at #{src_loc("BAD8B7FA")}: 'node' requires 'a' attribute to be set.", hint: desc do
      jaba do
        node :n # BAD8B7FA
      end
    end
    assert_jaba_file_error "'node' requires 'a' attribute to be set.", "3C869B0D" do
      "node :n # 3C869B0D"
    end
  end
end

jtest "rejects modifying read only attributes" do
  each_variant do |av, desc|
    jdl(level: :core) do
      attr :a, variant: av, type: :int do
        flags :read_only
      end
    end
    assert_jaba_error "Error at #{JTest.src_loc("D4AE68B1")}: 'a' attribute is read only.", hint: desc do
      jaba do
        __send__(:a, *JTest.make_args(av, 1)) # D4AE68B1
      end
    end
  end
end

jtest "supports setting a validator" do
  each_variant do |av, desc|
    jdl(level: :core) do
      attr :a, variant: av, type: :int do
        validate do |val|
          fail "failed"
        end
      end
      if av == :hash
        attr :b, variant: av, type: :int do
          validate_key do |key|
            fail "key failed"
          end
        end
      end
    end
    jaba do
      JTest.assert_jaba_error "Error at #{JTest.src_loc("78A6546B")}: 'a' attribute invalid - failed.", hint: desc do
        __send__(:a, *JTest.make_args(av, 1)) # 78A6546B
      end
      if av == :hash
        JTest.assert_jaba_error "Error at #{JTest.src_loc("2EDD4A7C")}: 'b' attribute invalid - key failed.", hint: desc do
          __send__(:b, *JTest.make_args(av, 1)) # 2EDD4A7C
        end
      end
    end
  end
end

jtest "arrays and hashes can be cleared" do
  each_variant do |av, desc|
    jdl(level: :core) do
      attr :a, variant: av, type: :int do
        key_type :int if av == :hash
        flags :allow_dupes if av == :array
      end
    end
    jaba do
      if av == :single
        JTest.assert_jaba_error "Error at #{JTest.src_loc("58A58F0F")}: Only array and hash attributes can be cleared.", hint: desc do
          clear :a # 58A58F0F
        end
      else
        5.times do |i|
          __send__(:a, *JTest.make_args(av, 1, key: i))
        end
        a.size.must_equal 5, msg: desc
        clear :a
        a.size.must_equal 0, msg: desc
        a.empty?.must_be_true(msg: desc)
      end
    end
  end
end
