class TestInput < JabaTest

  it 'can populate globals' do
    jaba(barebones: true, global_attrs: {'bool': 'true'}) do
      open_type :globals do
        attr :bool, type: :bool
      end
      type :test
      test :t do
        globals.bool.must_equal(true)
      end
    end
    jaba(global_attrs: {
      'bool1': 'true',
      'bool2': false,
      'a_string': 'str',
      'an_int': 1,
      'a_symbol': :symbol,
      'string_array': ['a', 'b', 'c'],
      'string_array_with_default': ['d', 'e', 'f'],
      'hash1': ['key1', 'value1', 'key2', '=value2', 'key3', 'value3='],
      'hash2': ['key1', 'value1', 'key2', 'value2', 'key3', 'value3']
      }) do
      open_type :globals do
        attr :bool1, type: :bool
        attr :bool2, type: :bool
        attr :bool3, type: :bool
        attr :a_string, type: :string
        attr :an_int, type: :int
        attr :a_symbol, type: :symbol
        # TODO: test reference attrs
        attr_array :string_array, type: :string
        attr_array :string_array_with_default, type: :string do
          default ['a', 'b', 'c']
        end
        attr_hash :hash1, key_type: :symbol, type: :string
        attr_hash :hash2, key_type: :string, type: :symbol
      end
      type :test
      test :t do
        globals.bool1.must_equal(true)
        globals.bool2.must_equal(false)
        globals.a_string.must_equal('str')
        globals.an_int.must_equal(1)
        globals.a_symbol.must_equal(:symbol)

        globals.string_array.must_equal(['a', 'b', 'c'])
        globals.string_array_with_default.must_equal(['a', 'b', 'c', 'd', 'e', 'f'])

        globals.hash1.must_equal({key1: 'value1', key2: '=value2', key3: 'value3='})
        globals.hash2.must_equal({'key1' => :value1, 'key2' => :value2, 'key3' => :value3})
      end
    end
  end

end
