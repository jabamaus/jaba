# frozen_string_literal: true

module JABA

  class TestInputManager < JabaTest

    describe 'failure conditions' do
      
      # TODO: should duplicate array options be allowed?
      it 'detects duplicate options' do
        #check_fail '--dry-run specified more than once' do
          #jaba(barebones: true, argv: ['--dry-run', '--dry-run'])
        #end
      end

    end

    it 'can populate globals from command line' do
      jaba(argv: ['-Dbool']) do
        open_type :globals do
          attr :bool, type: :bool
        end
        define :test
        test :t do
          globals.bool.must_equal(true)
        end
      end
      jaba(argv: [
        '-D', 'bool1',
        '-D', 'bool2', 'false',
        '-Dbool3', 'true',
        '-Da_string', 'str',
        '-Dstring_array', 'a', 'b', 'c',
        '-Dan_int', '1',
        '-Da_symbol', 'symbol',
        '--define', 'hash', 'key1', 'value1', 'key2', 'value2', '-Dhash', 'key3', 'value3'
        ]) do
        open_type :globals do
          attr :bool1, type: :bool
          attr :bool2, type: :bool
          attr :bool3, type: :bool
          attr :a_string, type: :string
          attr_array :string_array, type: :string
          attr :an_int, type: :int
          attr :a_symbol, type: :symbol
          attr_hash :hash, key_type: :symbol, type: :string
        end
        define :test
        test :t do
          globals.bool1.must_equal(true)
          globals.bool2.must_equal(false)
          globals.bool3.must_equal(true)
          globals.a_string.must_equal('str')
          globals.string_array.must_equal(['a', 'b', 'c'])
          globals.an_int.must_equal(1)
          globals.a_symbol.must_equal(:symbol)
          globals.hash.must_equal({key1: 'value1', key2: 'value2', key3: 'value3'})
        end
      end
    end

  end

end
