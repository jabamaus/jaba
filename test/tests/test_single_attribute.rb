# frozen_string_literal: false # Specifically want this false for a test

module JABA

  class TestSingleAttribute < JabaTest

    it 'only accepts single values' do
      check_fail "'a' attribute default must be a single value not a 'Array'", line: [__FILE__, 'tagV'] do
        jaba(barebones: true) do
          define :test do
            attr :a do
              default [] # tagV
            end
          end
        end
      end

      check_fail "'t.a' attribute must be a single value not a 'Array'", line: [__FILE__, 'tagK'] do
        jaba(barebones: true) do
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
      jaba(barebones: true) do
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

    it 'prevents modifying read values' do
      check_fail "Cannot modify read only value", line: [__FILE__, 'tagY'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :string do
              default 'b'
            end
          end
          test :t do
            val = a
            val.upcase! # tagY
            a.must_equal('b')
          end
        end
      end
      check_fail "Cannot modify read only value", line: [__FILE__, 'tagS'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :string do
            end
          end
          test :t do
            a 'b'
            val = a
            val.upcase! # tagS
          end
        end
      end
    end

    it 'works with block style default' do
      jaba(barebones: true) do
        define :test do
          attr :a
          attr :b
          attr :c do
            default do
              "#{a}_#{b}"
            end
          end
        end
        test :t do
          a 1
          b 2
          c.must_equal '1_2'
        end
      end

      # test with attr default using an unset attr
      #
      check_fail "Cannot read uninitialised 't.b' array attribute", line: [__FILE__, 'tagI'] do
        jaba(barebones: true) do
          define :test do
            attr :a
            attr_array :b
            attr :c do
              default do
                "#{a}_#{b.size}" # tagI
              end
            end
          end
          test :t do
            a 1
            c # TODO: this should be in trace
          end
        end
      end

      # test with another attr using unset attr
      #
      check_fail "Cannot read uninitialised 't.a' attribute", line: [__FILE__, 'tagF'] do
        jaba(barebones: true) do
          define :test do
            attr :a
            attr_array :b do
              default do
                [a] # tagF
              end
            end
          end
          test :t do
            b
          end
        end
      end
    end

    it 'fails if default block sets attribute' do
      check_fail "'t.a' attribute is read only", line: [__FILE__, 'tagA'] do
        jaba(barebones: true) do
          define :test do
            attr :a
            attr :b do
              default do
                a 1 # tagA
              end
            end
          end
          test :t do
          end
        end
      end
    end

    it 'validates flag options' do
      check_fail "Invalid flag option ':d' passed to 't.a' attribute. Valid flags are [:a, :b, :c]", line: [__FILE__, 'tagD'] do
        jaba(barebones: true) do
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

    it 'overwrites flag and keyval options on successive calls' do
      jaba(barebones: true) do
        define :test do
          attr :a do
            flag_options :fo1, :fo2, :fo3
            value_option :kv1
            value_option :kv2
            value_option :kv3
          end
        end
        test :t do
          a 1, :fo1, kv1: 2
          a 2, :fo2, :fo3, kv2: 3, kv3: 4
          generate do
            a = get_attr(:a)
            a.has_flag_option?(:fo1).must_equal(false)
            a.has_flag_option?(:fo2).must_equal(true)
            a.has_flag_option?(:fo3).must_equal(true)
            a.get_option_value(:kv1, fail_if_not_found: false).must_be_nil
            a.get_option_value(:kv2).must_equal(3)
            a.get_option_value(:kv3).must_equal(4)
          end
        end
      end
    end

    # TODO: check wiping down required values
    it 'supports wiping value back to default' do
      jaba(barebones: true) do
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
      check_fail "'t.a' attribute is read only", line: [__FILE__, 'tagJ'] do
        jaba(barebones: true) do
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

      # Check not settable even if no default supplied
      #
      check_fail "'t.a' attribute is read only", line: [__FILE__, 'tagC'] do
        jaba(barebones: true) do
          define :test do
            attr :a do
              flags :read_only
            end
          end
          test :t do
            a 1 # tagC
          end
        end
      end
    end

  end

end
