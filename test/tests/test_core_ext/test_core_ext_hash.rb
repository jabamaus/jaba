module JABA

  using JABACoreExt

  class TestCoreExtHash < JabaTest

    it 'supports push_value' do
      {}.push_value(:a, :b).must_equal(a: [:b])
      {}.push_value(:a, [:b]).must_equal(a: [:b])
      {}.push_value(:a, [:b, :c]).must_equal(a: [:b, :c])
      { a: [] }.push_value(:a, :b).must_equal(a: [:b])
      { a: [:b] }.push_value(:a, :c).must_equal(a: [:b, :c])
      { a: [:b] }.push_value(:a, [:c]).must_equal(a: [:b, :c])
      { a: [:b, :c] }.push_value(:a, [:d]).must_equal(a: [:b, :c, :d])
      { a: [:b, :c] }.push_value(:a, :d, clear: true).must_equal(a: [:d])
      { a: [:b, :c] }.push_value(:a, [:d], clear: true).must_equal(a: [:d])
    end
    
  end

end