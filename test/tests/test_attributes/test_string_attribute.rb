# frozen_string_literal: true

class TestStringAttribute < JabaTest

  it 'validates default' do
    assert_jaba_error "Error at #{src_loc(__FILE__, :tagP)}: ':a' attribute default invalid: ':not_a_string' is a symbol - expected a string." do
      jaba(barebones: true) do
        type :test do
          attr :a, type: :string do
            default :not_a_string # tagP
          end
        end
      end
    end
  end

  it 'can default to id' do
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

end
