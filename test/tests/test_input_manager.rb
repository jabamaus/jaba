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
      jaba(argv: [
        '--bool1',
        '--bool2', 'false',
        '--bool3', 'true',
        '--a-string', 'str',
        '--string-array', 'a', 'b', 'c',
        '--an-int', '1',
        '--a-symbol', 'symbol'
        ]) do
        open_type :globals do
          attr :bool1, type: :bool
          attr :bool2, type: :bool
          attr :bool3, type: :bool
          attr :a_string, type: :string
          attr_array :string_array, type: :string
          attr :an_int, type: :int
          attr :a_symbol, type: :symbol
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
        end
      end
    end

  end

end
