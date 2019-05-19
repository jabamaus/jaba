module JABA

class TestChoiceAttribute < JabaTest

  it 'requires items to be set' do
    check_fails("'items' must be set", backtrace: [[CoreTypesFile, "raise \"'items' must be set\""], [__FILE__, 'attr :a, type: :choice']]) do
      jaba do
        define :test do
          attr :a, type: :choice do
          end
        end
      end
    end
  end

  it 'rejects invalid choices' do
    check_fails("Must be one of [:a, :b, :c]", backtrace: [[CoreTypesFile, "raise \"must be one of"], [__FILE__, 'a :d']]) do
      jaba do
        define :test do
          attr :a, type: :choice do
            items [:a, :b, :c]
          end
        end
        test :t do
          a :d
        end
      end
    end
  end
  
end

end
