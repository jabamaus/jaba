# frozen_string_literal: true

module JABA

  class TestAttribute < JabaTest

    it 'rejects passing array to single value attribute' do
      check_fail "'a' attribute is not an array so cannot accept one", trace: [__FILE__, 'tagX'] do
        jaba do
          define :test do
            attr :a do
              default [1, 2] # tagX
            end
          end
          test :t
        end
      end
      
      check_fail "'a' attribute is not an array so cannot accept one", trace: [__FILE__, 'tagK'] do
        jaba do
          define :test do
            attr :a
          end
          test :t do
            a [1, 2] # tagK
          end
        end
      end
    end
    
    it 'allows setting value with block' do
      jaba do
        define :test do
          attr :a
          attr :b
        end
        test :t do
          b 1
          a do
            b + 1
          end
          a.must_equal 2
        end
      end
    end

    it 'validates flag options' do
      check_fail "Invalid flag option ':d'. Valid flags are [:a, :b, :c]", trace: [__FILE__, 'tagD'] do
        jaba do
          define :test do
            attr :a do
              flag_options :a, :b, :c
            end
          end
          test :t do
            a 1, :a, :b, :d # tagD
          end
        end
      end
    end

    # TODO: check wiping down required values
    it 'supports wiping value back to default' do
      jaba do
        define :test do
          attr :a do
            default 1
          end
          attr :b do
            default 'b'
          end
          attr :c do
            default :c
          end
          attr :d do
            default nil
          end
        end
        test :t do
          a.must_equal(1)
          a 2
          a.must_equal(2)
          b.must_equal('b')
          b 'bb'
          c.must_equal(:c)
          c :cc
          d.must_be_nil
          d 'd'
          d.must_equal('d')
          wipe :a
          wipe :b, :c, :d
          a.must_equal(1)
          b.must_equal('b')
          c.must_equal(:c)
          d.must_be_nil
        end
      end
    end
    
    it 'rejects setting readonly attrs' do
      check_fail "'a' attribute is read only", trace: [__FILE__, 'tagJ'] do
        jaba do
          define :test do
            attr :a do
              flags :read_only
              default 1
            end
          end
          test :t do
            a.must_equal(1)
            a 2 # tagJ
          end
        end
      end
    end

  end

end
