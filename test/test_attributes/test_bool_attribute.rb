jtest 'defaults to false' do
  jaba(barebones: true) do
    type :test do
      attr :a, type: :bool
    end
    test :t do
      a.must_equal(false)
    end
  end
end

jtest 'requires default to be true or false' do
  assert_jaba_error "Error at #{src_loc('2521765F')}: ':b' attribute default invalid: '1' is a integer - expected [true|false]" do
    jaba(barebones: true) do
      type :test do
        attr :b, type: :bool do
          default 1 # 2521765F
        end
      end
    end
  end
  jaba(barebones: true) do
    type :test do
      attr :b, type: :bool do
        default true
      end
      attr :c, type: :bool do
        default false
      end
    end
    test :t do
      b.must_equal(true)
      c.must_equal(false)
    end
  end
end

jtest 'only allows boolean values' do
  assert_jaba_error "Error at #{src_loc('0108AEFB')}: 'b.c' attribute invalid: '1' is a integer - expected [true|false]" do
    jaba(barebones: true) do
      type :test do
        attr :c, type: :bool do
          default true
        end
      end
      test :b do
        c 1 # 0108AEFB
      end
    end
  end
  jaba do
    type :test do
      attr :b, type: :bool do
        default true
      end
      attr :c, type: :bool do
        default false
      end
    end
    test :t do
      b false
      c true
      b.must_equal(false)
      c.must_equal(true)
    end
  end
end

jtest 'works with required flag' do
  assert_jaba_error "Error at #{src_loc('3C869B0D')}: 't.a' attribute requires a value. See #{src_loc('B959A565')}." do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :bool do # B959A565
          flags :required
        end
      end
      test :t do # 3C869B0D
      end
    end
  end
end

jtest 'can be set from global_attrs' do
  jaba(barebones: true, global_attrs: {
    'a1': 'true',
    'a2': false,
    'a3': '1',
    'a4': 0
    }) do
    open_type :globals do
      attr :a1, type: :bool do
        default false
      end
      attr :a2, type: :bool do
        default true
      end
      attr :a3, type: :bool do
        default false
      end
      attr :a4, type: :bool do
        default true
      end
    end
    type :test
    test :t do
      globals.a1.must_equal true
      globals.a2.must_equal false
      globals.a3.must_equal true
      globals.a4.must_equal false
    end
  end

  op = jaba(barebones: true, global_attrs: {'a': '10'}, want_exceptions: false) do
    open_type :globals do
      attr :a, type: :bool
    end
  end
  op[:error].must_equal "'10' invalid value for ':a' attribute - [true|false|0|1] expected"
end
