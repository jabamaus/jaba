# frozen_string_literal: false

class TestCoreExtArray < JabaTest

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
