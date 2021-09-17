class TestChoiceAttribute < JabaTest

  it 'requires items to be set' do
    assert_jaba_error "Error at #{src_loc(__FILE__, :tagA)}: ':a' attribute invalid: 'items' must be set." do
      jaba(barebones: true) do
        type :test do
          attr :a, type: :choice # tagA
        end
      end
    end
  end

  it 'warns if items contains duplicates' do
    assert_jaba_warn "'items' contains duplicates", __FILE__, :tagK do
      jaba(barebones: true) do
        type :test do
          attr :a, type: :choice do
            items [:a, :a, :b, :b] # tagK
          end
        end
      end
    end
  end
  
  it 'requires default to be in items' do
    assert_jaba_error "Error at #{src_loc(__FILE__, :tagB)}: ':a' attribute default invalid: Must be one of [1, 2, 3] but got '4'. See #{src_loc(__FILE__, :tagJ)}." do
      jaba(barebones: true) do
        type :test do
          attr :a, type: :choice do
            items [1, 2, 3] # tagJ
            default 4 # tagB
          end
        end
      end
    end
    assert_jaba_error "Error at #{src_loc(__FILE__, :tagC)}: ':a' array attribute default invalid: Must be one of [1, 2, 3] but got '4'. See #{src_loc(__FILE__, :tagH)}." do
      jaba(barebones: true) do
        type :test do
          attr_array :a, type: :choice do
            items [1, 2, 3] # tagH
            default [1, 2, 4] # tagC
          end
        end
      end
    end
  end

  it 'rejects invalid choices' do
    assert_jaba_error "Error at #{src_loc(__FILE__, :tagD)}: 't.a' attribute invalid: Must be one of [:a, :b, :c] but got ':d'. See #{src_loc(__FILE__, :tagM)}." do
      jaba(barebones: true) do
        type :test do
          attr :a, type: :choice do
            items [:a, :b, :c] # tagM
          end
        end
        test :t do
          a :d # tagD
        end
      end
    end
    assert_jaba_error "Error at #{src_loc(__FILE__, :tagE)}: 't.a' array attribute invalid: Must be one of [:a, :b, :c] but got ':d'. See #{src_loc(__FILE__, :tagX)}." do
      jaba(barebones: true) do
        type :test do
          attr_array :a, type: :choice do
            items [:a, :b, :c] # tagX
          end
        end
        test :t do
          a [:a, :b, :c, :d] # tagE
        end
      end
    end
  end

  it 'can be set from the cmd line' do
    jaba(barebones: true, argv: [
      '-D', 'a1', 'b',
      '-D', 'a2', '',
      '-D', 'a3', '1']) do
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

    op = jaba(barebones: true, argv: ['-D', 'a', 'd'], want_exceptions: false) do
      open_type :globals do
        attr :a, type: :choice do
          items [:a, :b, :c]
          default :a
        end
      end
    end
    op[:error].must_equal "'d' invalid value for ':a' attribute - [a|b|c] expected"
  end
end
