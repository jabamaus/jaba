module JabaTestMethods
  ATTR_VARIANTS = [:single, :array, :hash]
  ATTR_TYPES = JABA::Context.all_attr_type_names
  ATTR_TYPES.delete(:null)

  def coerce_to_variant(variant, val, key: :key)
    case variant
    when :single
      val
    when :array
      [val]
    when :hash
      { key => val }
    end
  end

  def make_args(variant, type, key: nil, single: false)
    val = case type
      when :basename
        "basename"
      when :bool
        false
      when :choice
        :a
      when :compound
        # handled by calling code
      when :dir
        "#{__dir__}/../../../examples/01-basic_app"
      when :ext
        ".ext"
      when :file
        "#{__dir__}/../../../examples/01-basic_app/basic_app.jaba"
      when :int
        1
      when :src
        "#{__dir__}/../../../examples/01-basic_app"
      when :string
        "string"
      when :to_s
        "to_s"
      when :uuid
        "uuid"
      else
        raise "unhandled attr type '#{type}'"
      end
    return val if single
    args = []
    args << coerce_to_variant(variant, val, key: key)
    args
  end

  def set_attr(receiver, attr_name, variant, type, key: :key)
    if type == :compound
      if variant == :hash
        raise "key must be specified" if key.nil?
        receiver.__send__(attr_name, key, __call_loc: Kernel.calling_location) do
        end
      else
        receiver.__send__(attr_name, __call_loc: Kernel.calling_location) do
        end
      end
    else
      receiver.__send__(attr_name, *make_args(variant, type, key: key), __call_loc: Kernel.calling_location)
    end
  end

  def each_attr(single: true, array: true, hash: true)
    ATTR_VARIANTS.each do |av|
      next if av == :single && !single
      next if av == :array && !array
      next if av == :hash && !hash
      ATTR_TYPES.each do |at, default|
        yield av, at, "(#{at} #{av})", default
      end
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

jtest "rejects modifying read only attributes" do
  each_attr do |av, at, desc, default_|
    jdl do
      attr :a, variant: av, type: at do
        flags :read_only
        items [:a, :b, :c] if at == :choice
        key_type :string if av == :hash
        default(*JTest.make_args(av, at)) if at != :compound
      end
    end
    assert_jaba_error "Error at #{JTest.src_loc("D4AE68B1")}: 'a' attribute is read only.", hint: desc do
      jaba do
        a(*JTest.make_args(av, at)) # D4AE68B1
      end
    end
  end
end

jtest "supports setting a validator" do
  each_attr do |av, at, desc|
    jdl(level: :core) do
      attr :a, variant: av, type: at do
        items [:a, :b, :c] if at == :choice
        key_type :string if av == :hash
        validate do |val|
          fail "failed"
        end
      end
      if av == :hash
        attr :b, variant: av, type: at do
          items [:a, :b, :c] if at == :choice
          key_type :string if av == :hash
          validate_key do |key|
            fail "key failed"
          end
        end
      end
    end
    jaba do
      JTest.assert_jaba_error "Error at #{JTest.src_loc("78A6546B")}: 'a' attribute invalid - failed.", hint: desc do
        JTest.set_attr(self, :a, av, at) # 78A6546B
      end
      if av == :hash
        JTest.assert_jaba_error "Error at #{JTest.src_loc("2EDD4A7C")}: 'b' attribute invalid - key failed.", hint: desc do
          JTest.set_attr(self, :b, av, at) # 2EDD4A7C
        end
      end
    end
  end
end

jtest "arrays and hashes can be cleared" do
  each_attr do |av, at, desc|
    jdl(level: :core) do
      attr :a, variant: av, type: at do
        items [:a, :b, :c] if at == :choice
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
          JTest.set_attr(self, :a, av, at, key: i)
        end
        a.size.must_equal 5, msg: desc
        clear :a
        a.size.must_equal 0, msg: desc
        a.empty?.must_be_true(msg: desc)
      end
    end
  end
end