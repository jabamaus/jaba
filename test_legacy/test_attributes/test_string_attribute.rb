jtest 'validates default' do
  assert_jaba_error "Error at #{src_loc('4847EA74')}: ':a' attribute default invalid: ':not_a_string' is a symbol - expected a string." do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :string do
          default :not_a_string # 4847EA74
        end
      end
    end
  end
end

jtest 'can default to id' do
  jaba(barebones: true) do
    type :test do
      attr :a, type: :string do
        default do
          id.to_s
        end
      end
    end
    test :t do
      generate do
        attrs.a.must_equal('t')
      end
    end
  end
end
