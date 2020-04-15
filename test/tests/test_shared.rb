# frozen_string_literal: true

module JABA

  class TestShared < JabaTest

    it 'allows inclusion of shared definitions in any object' do
      # check that all types support include directive
      #
      [:text, :project, :workspace, :category, :attr_type, :define].each do |type|
        check_fail 'Included', trace: [__FILE__, "fail 'Included'", __FILE__, '# tag1'] do
          jaba do
            shared :a do
              fail 'Included'
            end
            __send__(type, :t) do
              include :a # tag1
            end
          end
        end
      end
      
      jaba do
        shared :at_setup do
          init_attr_def do
            flags :allow_dupes
          end
        end
       
        attr_type :at do
          include :at_setup
        end
       
        shared :attr_setup do
          flags :unordered
        end
        
        shared :attrs do
          attr_array :a, type: :at do
            include :attr_setup
          end
        end
        define :test do
          include :attrs
        end
        test :t do
          a [3, 3, 2, 2, 1, 1]
          generate do
            attrs.a.must_equal [3, 3, 2, 2, 1, 1]
          end
        end
      end
    end

    it 'fails if shared definition does not exist' do
      check_fail "Shared definition 'b' not found", trace: [__FILE__, '# tag2'] do
        jaba do
          shared :a
          define :test
          test :c do
            include :b # tag2
          end
        end
      end
    end
    
    it 'supports passing args to shared definitions' do
      jaba do
        shared :a do |n1, s1, s2, s3, n2|
          c "#{s3}#{s1}#{n2}#{s2}#{n1}"
        end
        define :test do
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
      check_fail "Shared definition 'd' expects 3 arguments but 0 were passed", trace: [__FILE__, '# tag3'] do
        jaba do
          shared :d do |a1, a2, a3|
          end
          text :t do
            include :d # tag3
          end
        end
      end
      check_fail "Shared definition 'e' expects 0 arguments but 1 were passed", trace: [__FILE__, '# tag4'] do
        jaba do
          shared :e do
          end
          text :t do
            include :e, args: [1] # tag4
          end
        end
      end
      check_fail "Shared definition 'f' expects 2 arguments but 3 were passed", trace: [__FILE__, '# tag5'] do
        jaba do
          shared :f do |a1, a2|
          end
          text :t do
            include :f, args: [1, 2, 3] # tag5
          end
        end
      end
    end
    
    it 'can include multiple at once' do
    end
    
    it 'can chain includes' do
    end
    
  end

end
