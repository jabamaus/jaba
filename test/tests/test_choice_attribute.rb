module JABA

class TestChoiceAttribute < JabaTest

  it 'requires items to be set' do
    check_fails("'items' must be set", trace: [CoreTypesFile, "raise \"'items' must be set\"", __FILE__, '# tag1']) do
      jaba do
        define :test do
          attr :a, type: :choice do # tag1
          end
        end
      end
    end
  end
  
  it 'requires default to be in items' do
    check_fails("Must be one of [1, 2, 3]", trace: [CoreTypesFile, "raise \"must be one of", __FILE__, '# tag2']) do
      jaba do
        define :test do
          attr :a, type: :choice do # tag2
            items [1, 2, 3]
            default 4
          end
        end
      end
    end
    check_fails("Must be one of [1, 2, 3]", trace: [CoreTypesFile, "raise \"must be one of", __FILE__, '# tag3']) do
      jaba do
        define :test do
          attr_array :a, type: :choice do # tag3
            items [1, 2, 3]
            default [1, 2, 4]
          end
        end
      end
    end
  end

  it 'rejects invalid choices' do
    check_fails("Must be one of [:a, :b, :c]", trace: [CoreTypesFile, "raise \"must be one of", __FILE__, '# tag4']) do
      jaba do
        define :test do
          attr :a, type: :choice do
            items [:a, :b, :c]
          end
        end
        test :t do
          a :d # tag4
        end
      end
    end
    check_fails("Must be one of [:a, :b, :c]", trace: [CoreTypesFile, "raise \"must be one of", __FILE__, '# tag5']) do
      jaba do
        define :test do
          attr_array :a, type: :choice do
            items [:a, :b, :c]
          end
        end
        test :t do
          a [:a, :b, :c, :d] # tag5
        end
      end
    end
  end
  
end

end