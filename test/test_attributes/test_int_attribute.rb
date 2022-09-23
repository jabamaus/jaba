jtest 'validates default' do
  assert_jaba_error "Error at #{src_loc('9A0B23C7')}: ':a' attribute default invalid: 'not an int' is a string - expected an integer." do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :int do
          default 'not an int' # 9A0B23C7
        end
      end
    end
  end
end

jtest 'validates value' do
  assert_jaba_error "Error at #{src_loc('F616E4F3')}: 't.a' attribute invalid: 'true' is a boolean - expected an integer." do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :int
      end
      test :t do
        a true # F616E4F3
      end
    end
  end
end

jtest "fails if value not supplied when 'required' flag specified" do
  assert_jaba_error "Error at #{src_loc('ED8FC1AC')}: 't.a' attribute requires a value. See #{src_loc('DF306F8F')}." do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :bool do # DF306F8F
          flags :required
        end
      end
      test :t # ED8FC1AC
    end
  end
end

jtest 'supports standard ops' do
  jaba(barebones: true) do
    type :test do
      attr :a, type: :int
      attr :b, type: :int do
        default 1
      end
      attr_array :aa, type: :int
      attr_array :ba, type: :int do
        default [3, 4, 5]
      end
      attr_hash :ah, type: :int, key_type: :symbol
      attr_hash :bh, type: :int, key_type: :symbol do
        default({k1: 1})
      end
    end
    test :t do
      a.must_equal(0) # Defaults to 0 if :required flag not used
      b.must_equal(1) # Works with a default
      a 2
      a.must_equal(2)
      b 3
      b.must_equal(3)

      # test array attrs
      aa.must_equal []
      aa [1, 2, 3]
      aa.must_equal [1, 2, 3]
      ba.must_equal [3, 4, 5]
      ba [6, 7, 8]
      ba.must_equal [3, 4, 5, 6, 7, 8]

      # test hash attrs
      ah.must_equal({})
      ah :k1, 1
      ah.must_equal({k1: 1})
      bh.must_equal({k1: 1})
      bh :k1, 2
      bh.must_equal({k1: 2})
      bh :k2, 3
      bh.must_equal({k1: 2, k2: 3})
    end
  end
end

jtest 'can be set from global attrs' do
  jaba(barebones: true, global_attrs: {
    'a1': '1',
    'a2': '3433409',
    'a3': '-1',
    'a4': '0'
    }) do
    open_type :globals do
      attr :a1, type: :int
      attr :a2, type: :int 
      attr :a3, type: :int
      attr :a4, type: :int
    end
    type :test
    test :t do
      globals.a1.must_equal(1)
      globals.a2.must_equal(3433409)
      globals.a3.must_equal(-1)
      globals.a4.must_equal(0)
    end
  end

  op = jaba(barebones: true, global_attrs: {'a': 'foo'}, want_exceptions: false) do
    open_type :globals do
      attr :a, type: :int
    end
  end
  op[:error].must_equal "'foo' invalid value for ':a' attribute - integer expected"
end
