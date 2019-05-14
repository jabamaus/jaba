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
  
  it 'allows flagging arrays as unordered' do
    jaba do
      define :test do
        attr :a do
          flags :array, :unordered, :allow_dupes
        end
      end
      test :t do
        a ['j', 'a', 'b', 'a']
        generate do
          a.must_equal ['j', 'a', 'b', 'a']
        end
      end
    end
  end
  
  it 'supports prefix and suffix options' do
    jaba do
      define :test do
        attr :a do
          flags :array, :unordered, :allow_dupes
        end
      end
      test :t do
        a ['j', 'a', 'b', 'a'], prefix: '1', suffix: 'z'
        generate do
          a.must_equal ['1jz', '1az', '1bz', '1az']
        end
      end
    end
  end
  
  it 'only allows prefix/suffix on string elements' do
    check_fails('Prefix/suffix option can only be used with arrays of strings', backtrace: [[__FILE__, 'a [1, 2, 3]']]) do
      jaba do
        define :test do
          attr :a do
            flags :array
          end
        end
        test :t do
          a [1, 2, 3], prefix: 'a', suffix: 'b'
        end
      end
    end
  end
  
  it 'supports excluding elements' do
    jaba do
      define :test do
        attr :a do
          flags :array
        end
        attr :b do
          flags :array
        end
      end
      test :t do
        a :a
        a [:b], exclude: [:c]
        a [:c, :d, :e], exclude: [:d, :e]
        b [1, 2, 3, 4]
        b exclude: [2, 3]
        generate do
          a.must_equal [:a, :b]
          b.must_equal [1, 4]
        end
      end
    end
  end

  it 'supports excluding elements with regexes' do
    jaba do
      define :test do
        attr :a do
          flags :array
        end
      end
      test :t do
        a ['one', 'two', 'three', 'four']
        a exclude: [/o/, 'three']
        generate do
          a.must_equal []
        end
      end
    end
  end
  
  it 'fails if excluding with regex on non-strings' do
    check_fails('Exclude regex can only operate on strings', backtrace: [[__FILE__, 'a [1, 2, 3, 4, 43]']]) do
      jaba do
        define :test do
          attr :a do
            flags :array
          end
        end
        test :t do
          a [1, 2, 3, 4, 43], exclude: [/3/]
        end
      end
    end
  end
  
  it 'supports conditional excluding' do
    jaba do
      define :test do
        attr :a do
          flags :array
        end
        attr :b do
          flags :array
        end
      end
      test :t do
        a [:a]
        a [:b, :c], exclude: lambda {|e| e == :e}
        a [:d, :e], exclude: lambda {|e| e == :d or e == :c}
        b [1, 2, 3, 4], exclude: lambda {|e| e > 2}
        generate do
          a.must_equal [:a, :b]
          b.must_equal [1, 2]
        end
      end
    end
  end
  
end

end