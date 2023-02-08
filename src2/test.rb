require_relative 'services'

jtest 'split_jdl_path' do
  parent, elem = 'a|b|c'.split_jdl_path
  parent.must_equal 'a|b'
  elem.must_equal 'c'
  'a|b'.split_jdl_path.must_equal ['a', 'b']
  'a'.split_jdl_path.must_equal [nil, 'a']
end

