module JABA

class TestShared < JabaTest

  it 'allows inclusion of shared definitions in any object' do
   # TODO: check backtrace includes include statement
    [:text, :project, :workspace, :category].each do |type| # TODO: include :shared
      check_fails('Included', backtrace: [[__FILE__, "raise 'Included'"]]) do
        jaba do
          shared :a do
            raise 'Included'
          end
          __send__(type, :t) do
            include :a
          end
        end
      end
    end
    # TODO: extend to test types
  end

  it 'fails if shared definition does not exist' do
    check_fails("Shared definition 'b' not found", backtrace: [[__FILE__, 'include :b']]) do
      jaba do
        shared :a do
        end
        text :c do
          include :b
        end
      end
    end
  end
  
  it 'supports passing args to shared definitions' do
    jaba do
      shared :a do |n1, s1, s2, s3, n2|
        content "#{s3}#{s1}#{n2}#{s2}#{n1}"
      end
      1.upto(10) do |n|
        text "t#{n}" do
          include :a, args: [n, 'a', 'b', 'c', 4]
          content.must_equal("ca4b#{n}")
        end
      end
    end
  end
  
  it 'catches argument mismatches' do
    check_fails("Shared definition 'd' expects 3 arguments but 0 were passed", backtrace: [[__FILE__, 'include :d']]) do
      jaba do
        shared :d do |a1, a2, a3|
        end
        text :t do
          include :d
        end
      end
    end
    check_fails("Shared definition 'e' expects 0 arguments but 1 were passed", backtrace: [[__FILE__, 'include :e, args: [1]']]) do
      jaba do
        shared :e do
        end
        text :t do
          include :e, args: [1]
        end
      end
    end
    check_fails("Shared definition 'f' expects 2 arguments but 3 were passed", backtrace: [[__FILE__, 'include :f, args: [1, 2, 3]']]) do
      jaba do
        shared :f do |a1, a2|
        end
        text :t do
          include :f, args: [1, 2, 3]
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
