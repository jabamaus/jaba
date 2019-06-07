# frozen_string_literal: true

module JABA
  using JABACoreExt

  class TestUtils < JabaTest
    
    describe 'Hash' do
    
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
    
    describe 'String' do
      
      it 'can clean path' do
        'a'.cleanpath.must_equal('a')
        'a/b'.cleanpath.must_equal('a/b')
        'a/b/'.cleanpath.must_equal('a/b')
        '.'.cleanpath.must_equal('.')
        './'.cleanpath.must_equal('.')
        '/'.cleanpath.must_equal('/')
        '..'.cleanpath.must_equal('..')
        '../'.cleanpath.must_equal('..')
        './a/../b/../'.cleanpath.must_equal('.')
        '.\\a\\..\\b\\..\\'.cleanpath.must_equal('.')
        'C:/a/b/..'.cleanpath.must_equal('C:/a')
        'C:\\a\\b\\..'.cleanpath.must_equal('C:/a')
      end
      
    end
    
  end
  
end
