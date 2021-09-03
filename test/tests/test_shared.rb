# frozen_string_literal: true

module JABA

  class TestShared < JabaTest

    it 'allows inclusion of shared definitions in any object' do
      # check that all types support include directive
      #
      [:text, :workspace, :category, :type].each do |type|
        check_fail 'Included', line: [__FILE__, "fail 'Included'"], trace: [__FILE__, 'tagG'] do
          jaba do
            shared :a do
              fail 'Included'
            end
            __send__(type, :t) do
              include :a # tagG
            end
          end
        end
      end
      
      jaba(barebones: true) do
        shared :attr_setup do
          flags :no_sort
        end
        
        shared :attrs do
          attr_array :a do
            include :attr_setup
          end
        end
        type :test do
          include :attrs
        end
        test :t do
          a [3, 2, 1]
          a.must_equal [3, 2, 1]
        end
      end
    end

    it 'fails if no block supplied' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagP)}: 'shared' definition requires a block." do
        jaba(barebones: true) do
          shared :a # tagP
        end
      end
    end

    it 'fails if shared definition does not exist' do
      check_fail "Shared definition 'b' not found", line: [__FILE__, 'tagT'] do
        jaba(barebones: true) do
          shared :a do
          end
          type :test
          test :c do
            include :b # tagT
          end
        end
      end
    end
    
    it 'supports passing args to shared definitions' do
      jaba(barebones: true) do
        shared :a do |n1, s1, s2, s3, n2|
          c "#{s3}#{s1}#{n2}#{s2}#{n1}"
        end
        type :test do
          attr :c
        end
        1.upto(10) do |n|
          test "t#{n}" do
            include :a, args: [n, 'a', 'b', 'c', 4]
            c.must_equal("ca4b#{n}")
          end
        end
      end
    end
    
    it 'catches argument mismatches' do
      check_fail "Shared definition 'd' expects 3 arguments but 0 were passed", line: [__FILE__, 'tagW'] do
        jaba do
          shared :d do |a1, a2, a3|
          end
          text :t do
            include :d # tagW
          end
        end
      end
      check_fail "Shared definition 'e' expects 0 arguments but 1 were passed", line: [__FILE__, 'tagU'] do
        jaba do
          shared :e do
          end
          text :t do
            include :e, args: [1] # tagU
          end
        end
      end
      check_fail "Shared definition 'f' expects 2 arguments but 3 were passed", line: [__FILE__, 'tagB'] do
        jaba do
          shared :f do |a1, a2|
          end
          text :t do
            include :f, args: [1, 2, 3] # tagB
          end
        end
      end
    end
    
    it 'can chain includes' do
    end
    
  end

end
