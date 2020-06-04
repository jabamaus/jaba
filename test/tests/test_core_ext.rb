module JABA

  using JABACoreExt

  class TestCoreExt < JabaTest
    
    describe 'String' do
      
      it 'supports split_path' do
        '.'.split_path.must_equal []
        'a'.split_path.must_equal ['a']
        '/'.split_path.must_equal []
        'a/b/c/d'.split_path.must_equal ['a', 'b', 'c', 'd']
        'aaa/bbb/ccc/ddd'.split_path.must_equal ['aaa', 'bbb', 'ccc', 'ddd']
        'a\\b\\c\\d'.split_path.must_equal ['a', 'b', 'c', 'd']
        'a/b/c'.split_path.must_equal ['a', 'b', 'c']
        'a//b//c//d'.split_path.must_equal ['a', 'b', 'c', 'd']        
        'a////b///////c\\\\\\d'.split_path.must_equal ['a', 'b', 'c', 'd']
        '///'.split_path.must_equal []
        '\\'.split_path.must_equal []
        'C:'.split_path.must_equal ['C:']
        'C:/'.split_path.must_equal ['C:']
        'C:/a/bb/'.split_path.must_equal ['C:', 'a', 'bb']
        '../../../'.split_path.must_equal ['..', '..', '..']
        '/../../../'.split_path.must_equal ['..', '..', '..']
        '.aa/./bb'.split_path.must_equal ['.aa', 'bb']
        './'.split_path.must_equal []
        './././'.split_path.must_equal []
        './/.\\.\\.\\'.split_path.must_equal []
        'a.b.c'.split_path.must_equal ['a.b.c']
        '..'.split_path.must_equal ['..']
        '/a/b'.split_path(preserve_absolute_unix: true).must_equal ['/', 'a', 'b']
        # TODO: test some cleaning
       end

      it 'supports clean_path' do
        ''.cleanpath.must_equal('.')
        '.'.cleanpath.must_equal('.')
        './'.cleanpath.must_equal('.')
        '/'.cleanpath.must_equal('/')
        '/.'.cleanpath.must_equal('/')
        '/./'.cleanpath.must_equal('/')
        '..'.cleanpath.must_equal('..')
        '../'.cleanpath.must_equal('..')
        'a'.cleanpath.must_equal('a')
        'aaaa'.cleanpath.must_equal('aaaa')
        'a/b'.cleanpath.must_equal('a/b')
        'aaaa/bbbb'.cleanpath.must_equal('aaaa/bbbb')
        'a/b/'.cleanpath.must_equal('a/b')
        'aaaa/bbbb/'.cleanpath.must_equal('aaaa/bbbb')
        'a/b/c/d'.cleanpath.must_equal('a/b/c/d')
        'a/b/c/d.e'.cleanpath.must_equal('a/b/c/d.e')
        '.a'.cleanpath.must_equal('.a')
        'a/.'.cleanpath.must_equal('a')
        '/a/b'.must_equal('/a/b')
        './a/../b/../'.cleanpath.must_equal('.')
        '.\\a\\..\\b\\..\\'.cleanpath.must_equal('.')
        'C:'.cleanpath.must_equal('C:')
        'c:'.cleanpath.must_equal('C:')
        'C:/a/b/..'.cleanpath.must_equal('C:/a')
        'C:\\a\\b\\..'.cleanpath.must_equal('C:/a')
        '/a/**/b.*'.cleanpath.must_equal('/a/**/b.*')
        'a/b/..'.cleanpath.must_equal('a')
        'a/../b/c/../../'.cleanpath.must_equal('.')
        'a/../b/c/../**/'.cleanpath.must_equal('b/**')
        "a\\..\\b\\c\\..\\**\\".cleanpath.must_equal('b/**')
        "a\\../b\\c\\../**\\".cleanpath.must_equal('b/**')
        '$(ENV_VAR)'.cleanpath.must_equal('$(ENV_VAR)')
        '//'.cleanpath.must_equal('//') # UNC, albeit invalid
        '//a////b//'.cleanpath.must_equal('//a/b') # UNC
        'a//b'.cleanpath(validate: true) do |clean|
          clean.must_equal('a/b')
        end
      end

      it 'supports relative_path_from' do
        'a/b/c'.relative_path_from(nil).must_equal('a/b/c')
        '.'.relative_path_from('.').must_equal('.')
        'a'.relative_path_from('a').must_equal('.')
        'a/b/c/d'.relative_path_from('a/b/c/d').must_equal('.')
        '/'.relative_path_from('/').must_equal('.')
        'C:/'.relative_path_from('C:/').must_equal('.')
        'C:'.relative_path_from('C:').must_equal('.')
        'a'.relative_path_from('a/b/c').must_equal('../..')
        'a/b/c'.relative_path_from('d').must_equal('../a/b/c')
        'e'.relative_path_from('a/b/c').must_equal('../../../e')
        'a/../b/.././c'.relative_path_from('d').must_equal('../c')
        'C:/a/b/c'.relative_path_from('C:/a/b').must_equal('c')
        'C:/a/b/c/d/e/f.rb:12'.relative_path_from('C:/a/b/c').must_equal('d/e/f.rb:12') # test can use on ruby source file locations
        assert_raises RuntimeError do
          'a'.relative_path_from('/')
        end.message.must_match("Cannot turn 'a' into a relative path from '/' - paths are unrelated")
        assert_raises RuntimeError do
          'a'.relative_path_from("C:")
        end
        assert_raises RuntimeError do
          'C:/'.relative_path_from('D:/')
        end.message.must_match('paths are unrelated')
        assert_raises RuntimeError do
          'C:/'.relative_path_from('D:/a/b/c')
        end.message.must_match('paths are unrelated')
        assert_raises RuntimeError do
          'C:/a/b/c'.relative_path_from('x/y/z')
        end.message.must_match('paths are unrelated')
        '//a/b'.relative_path_from('//a/b/c').must_equal('..')
        'a\\b\\c'.relative_path_from('d').must_equal('../a/b/c')
        'a\\b\\c'.relative_path_from('d', backslashes: true).must_equal('..\\a\\b\\c')
        'a/b/c'.relative_path_from('d', backslashes: true).must_equal('..\\a\\b\\c')

        # The nil_if_dot and no_dot_dot options are used when generating vcxproj.filters files.
        # 'nil_if_dot: true' returns nil in the case that the path ends up as '.'
        # 'no_dot_dot: true' causes resulting relative path not to be filled with '..'. Used when generated vcxproj.filters files.
        #
        '.'.relative_path_from('.', nil_if_dot: true).must_be_nil
        'a/b/c/d'.relative_path_from('a/b/c/d', nil_if_dot: true).must_be_nil
        'a'.relative_path_from('a/b/c', no_dot_dot: true).must_equal('.')
        'a'.relative_path_from('a/b/c', no_dot_dot: true, nil_if_dot).must_be_nil
        'e'.relative_path_from('a/b/c', no_dot_dot: true).must_equal('e')
      end
      
      it 'supports absolute_unix_path?' do
        ''.absolute_path?.must_equal(false)
        '/'.absolute_unix_path?.must_equal(true)
        '/a/b'.absolute_unix_path?.must_equal(true)
        '//'.absolute_unix_path?.must_equal(false)
        'C:'.absolute_unix_path?.must_equal(false)
        'a'.absolute_unix_path?.must_equal(false)
        '.'.absolute_unix_path?.must_equal(false)
      end

      it 'supports absolute_path?' do
        ''.absolute_path?.must_equal(false)
        '/'.absolute_path?.must_equal(true)
        'C:'.absolute_path?.must_equal(true)
        'C:/'.absolute_path?.must_equal(true)
        'C:/temp'.absolute_path?.must_equal(true)
        'C:\\Program Files'.absolute_path?.must_equal(true)
        '/usr/bin'.absolute_path?.must_equal(true)
        '../'.absolute_path?.must_equal(false)
        '.'.absolute_path?.must_equal(false)
      end

      it 'supports to_absolute' do
        cwd = Dir.getwd
        'C:'.to_absolute.must_equal('C:')
           'C:/a/b/c'.to_absolute.must_equal('C:/a/b/c')
        '/'.to_absolute.must_equal('/')
        '/a'.to_absolute.must_equal('/a')
        '..'.to_absolute(clean: true).must_equal("#{cwd}/..".cleanpath)
        'a'.to_absolute.must_equal("#{cwd}/a")
        '.'.to_absolute.must_match(cwd)
        '././a/b/../../.'.to_absolute(clean: true).must_equal(cwd)
      end

      it 'supports last_path_component' do
        'a'.last_path_component.must_equal('a')
        'a/b'.last_path_component.must_equal('b')
        'a/b/'.last_path_component.must_equal('b')
        'a\\b\\'.last_path_component.must_equal('b')
        'a/b.c'.last_path_component.must_equal('b.c')
        'a/b.c.d'.last_path_component.must_equal('b.c.d')
        ''.last_path_component.must_equal('')
        '/'.last_path_component.must_equal('/')
        'C:'.last_path_component.must_equal('C:')
        'C:/'.last_path_component.must_equal('C:')
        '../a.b'.last_path_component.must_equal('a.b')
        'a/b.c:12'.last_path_component.must_equal('b.c:12') # test works with ruby source file location
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

      it 'supports remove_and_return_dupes' do
        a = [1, 2, 3, 4]
        a.remove_and_return_dupes.must_be_nil
        a.must_equal [1, 2, 3, 4]
        a = [1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 5]
        a.remove_and_return_dupes.must_equal [1, 2, 3]
        a.must_equal [1, 2, 3, 4, 5]
      end

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
