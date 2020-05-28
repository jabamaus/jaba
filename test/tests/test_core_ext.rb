module JABA

  using JABACoreExt

  class TestCoreExt < JabaTest
    
    describe 'String' do
      
      it 'supports split_path' do
        '.'.split_path.must_equal ['.']
        'a'.split_path.must_equal ['a']
        '/'.split_path.must_equal ['/']
        'a/b/c/d'.split_path.must_equal ['a', 'b', 'c', 'd']
        'aaa/bbb/ccc/ddd'.split_path.must_equal ['aaa', 'bbb', 'ccc', 'ddd']
        'a\\b\\c\\d'.split_path.must_equal ['a', 'b', 'c', 'd']
        '/a/b/c'.split_path.must_equal ['/', 'a', 'b', 'c']
        'a//b//c//d'.split_path.must_equal ['a', 'b', 'c', 'd']        
        'a////b///////c\\\\\\d'.split_path.must_equal ['a', 'b', 'c', 'd']
        '///'.split_path.must_equal ['/']
        '\\'.split_path.must_equal ['/']
        'C:'.split_path.must_equal ['C:']
        'C:/'.split_path.must_equal ['C:']
        'C:/a/bb/'.split_path.must_equal ['C:', 'a', 'bb']
        '../../../'.split_path.must_equal ['..', '..', '..']
        '/../../../'.split_path.must_equal ['/', '..', '..', '..']
        '.aa/./bb'.split_path.must_equal ['.aa', 'bb']
        './'.split_path.must_equal ['.']
        './././'.split_path.must_equal ['.']
        './/.\\.\\.\\'.split_path.must_equal ['.']
        'a.b.c'.split_path.must_equal ['a.b.c']
       end

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
      
      it 'supports absolute_path?' do
        'C:/temp'.absolute_path?.must_equal(true)
        'C:\\Program Files'.absolute_path?.must_equal(true)
        '/usr/bin'.absolute_path?.must_equal(true)
        '../'.absolute_path?.must_equal(false)
        '.'.absolute_path?.must_equal(false)
      end

      it 'supports quote!' do
        'p'.quote!.must_equal('"p"')
        '"p"'.quote!.must_equal('"p"')
        '"p'.quote!.must_equal('""p"')
        'p"'.quote!.must_equal('"p""')
        'p'.quote!('foo').must_equal('foopfoo')
      end

      it 'supports vs_quote!' do
        'p'.vs_quote!.must_equal('p') # no space or macro, no quote
        '"p"'.vs_quote!.must_equal('"p"') # no space or macro, no quote
        '"p'.vs_quote!.must_equal('"p') # no space or macro, no quote
        'p"'.vs_quote!.must_equal('p"') # no space or macro, no quote
        ' p'.vs_quote!.must_equal('" p"') # space, quote
        '$(Var)'.vs_quote!.must_equal('"$(Var)"')   # macro, quote
      end

    end

    describe 'Array' do

      it 'supports vs_join' do
        [].vs_join.must_be_nil
        [].vs_join(inherit: '%(var)').must_be_nil
        [].vs_join(inherit: '%(var)', force: true).must_equal('%(var)')
        [''].vs_join.must_be_nil
        ['x'].vs_join.must_equal('x')
        ['x', 'y', 'z'].vs_join.must_equal('x;y;z')
        ['x', 'y', 'z'].vs_join(separator: ' ', inherit: '%(var)').must_equal('x y z %(var)')
      end
      
      it 'supports vs_join_paths' do
        [].vs_join_paths.must_be_nil
        [].vs_join_paths(inherit: '%(var)').must_be_nil
        [].vs_join_paths(inherit: '%(var)', force: true).must_equal('%(var)')
        [''].vs_join_paths.must_be_nil
        [''].vs_join_paths(force: true).must_equal('')
        ['', '', ''].vs_join_paths.must_equal(';;')
        ['a'].vs_join_paths.must_equal('a')
        ['a', 'b', 'c'].vs_join_paths.must_equal('a;b;c')
        ['a/b', 'c/d', 'e/f/g'].vs_join_paths.must_equal('a\b;c\d;e\f\g')
        ['a b', '$(var)/c'].vs_join_paths.must_equal('"a b";"$(var)\c"')
        ['a', 'b', 'c'].vs_join_paths(separator: ' ').must_equal('a b c')
        ['a', 'b', 'c'].vs_join_paths(inherit: '%(var)').must_equal('a;b;c;%(var)')
      end

    end
    
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

  end
  
end
