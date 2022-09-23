jtest 'requires items to be set' do
  assert_jaba_error "Error at #{src_loc('A2047AFC')}: ':a' attribute invalid: 'items' must be set." do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :choice # A2047AFC
      end
    end
  end
end

jtest 'warns if items contains duplicates' do
  assert_jaba_warn "'items' contains duplicates", __FILE__, '234928DC' do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :choice do
          items [:a, :a, :b, :b] # 234928DC
        end
      end
    end
  end
end

jtest 'requires default to be in items' do
  assert_jaba_error "Error at #{src_loc('8D88FA0D')}: ':a' attribute default invalid: Must be one of [1, 2, 3] but got '4'. See #{src_loc('1BDF16B5')}." do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :choice do
          items [1, 2, 3] # 1BDF16B5
          default 4 # 8D88FA0D
        end
      end
    end
  end
  assert_jaba_error "Error at #{src_loc('CDCFF3A7')}: ':a' array attribute default invalid: Must be one of [1, 2, 3] but got '4'. See #{src_loc('0C81C8C8')}." do
    jaba(barebones: true) do
      type :test do
        attr_array :a, type: :choice do
          items [1, 2, 3] # 0C81C8C8
          default [1, 2, 4] # CDCFF3A7
        end
      end
    end
  end
end

jtest 'rejects invalid choices' do
  assert_jaba_error "Error at #{src_loc('21E33D49')}: 't.a' attribute invalid: Must be one of [:a, :b, :c] but got ':d'. See #{src_loc('F0E843B4')}." do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :choice do
          items [:a, :b, :c] # F0E843B4
        end
      end
      test :t do
        a :d # 21E33D49
      end
    end
  end
  assert_jaba_error "Error at #{src_loc('E22800D3')}: 't.a' array attribute invalid: Must be one of [:a, :b, :c] but got ':d'. See #{src_loc('5D58D438')}." do
    jaba(barebones: true) do
      type :test do
        attr_array :a, type: :choice do
          items [:a, :b, :c] # 5D58D438
        end
      end
      test :t do
        a [:a, :b, :c, :d] # E22800D3
      end
    end
  end
end

jtest 'can be set from global attrs' do
  jaba(barebones: true, global_attrs: {
    'a1': 'b',
    'a2': '',
    'a3': '1'
    }) do
    open_type :globals do
      attr :a1, type: :choice do
        items [:a, :b, :c]
        default :a
      end
      attr :a2, type: :choice do
        items [:a, :b, :c, nil]
        default :a
      end
      attr :a3, type: :choice do
        items [1, :a, 'b']
        default 'b'
      end
    end
    type :test
    test :t do
      globals.a1.must_equal :b
      globals.a2.must_be_nil
      globals.a3.must_equal 1
    end
  end

  op = jaba(barebones: true, global_attrs: {'a': 'd'}, want_exceptions: false) do
    open_type :globals do
      attr :a, type: :choice do
        items [:a, :b, :c]
        default :a
      end
    end
  end
  op[:error].must_equal "'d' invalid value for ':a' attribute - [a|b|c] expected"
end
