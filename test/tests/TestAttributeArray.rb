module JABA

class TestAttributeArray < JabaTest

  it 'strips duplicates by default' do
    op = jaba do
      define :test do
        attr :a do
          flags :array
        end
      end
      test :t do
        a [5, 5, 6, 6, 7, 7, 7]
        a.must_equal [5, 5, 6, 6, 7, 7, 7]
        generate do
          a.must_equal [5, 6, 7]
        end
      end
    end
    #op.warnings.must_equal(["Warning at TestAttributeArray.rb:6: 'a' array attribute contains duplicates"]) # TODO: turn into check_warn util
  end
  
  it 'allows flagging arrays with :allow_dupes' do
    jaba do
      define :test do
        attr :a do
          flags :array, :allow_dupes
        end
      end
      test :t do
        a [5, 5, 6, 6, 7, 7, 7]
        generate do
          a.must_equal [5, 5, 6, 6, 7, 7, 7]
        end
      end
    end
  end
  
  it 'sorts by default' do
    jaba do
      define :test do
        attr :a do
          flags :array
        end
        attr :b do
          flags :array
        end
        attr :c do
          flags :array
        end
        attr :d do
          flags :array
        end
      end
      test :t do
        a [5, 4, 2, 1, 3]
        b ['e', 'c', 'a', 'A', 'C']
        c [10.34, 3, 800.1, 0.01, -1]
        d [:e, :c, :a, :A, :C]
        generate do
          a.must_equal [1, 2, 3, 4, 5]
          b.must_equal ['a', 'A', 'c', 'C', 'e']
          c.must_equal [-1, 0.01, 3, 10.34, 800.1]
          d.must_equal [:a, :A, :c, :C, :e]
        end
      end
    end
  end
  
  it 'does not sort bool arrays' do
    jaba do
      define :test do
        attr :a do
          type :bool
          flags :array
        end
      end
      test :t do
        a [true, false, false, true]
        generate do
          a.must_equal [true, false, false, true]
        end
      end
    end
  end
  
end

end
