module JABA

class TestChoiceAttribute < JabaTest

  it 'requires items to be set' do
    check_fails("'items' must be set", backtrace: [[CoreTypesFile, "raise \"'items' must be set\""], [__FILE__, '# tag1']]) do
      jaba do
        define :test do
          attr :a, type: :choice do # tag1
          end
        end
      end
    end
  end

  it 'rejects invalid choices' do
    check_fails("Must be one of [:a, :b, :c]", backtrace: [[CoreTypesFile, "raise \"must be one of"], [__FILE__, '# tag2']]) do
      jaba do
        define :test do
          attr :a, type: :choice do
            items [:a, :b, :c]
          end
        end
        test :t do
          a :d # tag2
        end
      end
    end
    check_fails("Must be one of [:a, :b, :c]", backtrace: [[CoreTypesFile, "raise \"must be one of"], [__FILE__, '# tag3']]) do
      jaba do
        define :test do
          attr :a, type: :choice do
            flags :array
            items [:a, :b, :c]
          end
        end
        test :t do
          a [:a, :b, :c, :d] # tag3
        end
      end
    end
  end
  
end

end
