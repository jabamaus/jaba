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

    it 'can populate an instance from command line' do
      jaba(barebones: true, argv: [
        '--a_bool',
        '--a_string', 'str',
        '--string_array', 'a', 'b', 'c',
        '--an_int', '1',
        '--a_symbol', 'symbol'
        ]) do
        open_type :input do
          attr :a_bool, type: :bool
          attr :a_string, type: :string
          attr_array :string_array, type: :string
          attr :an_int, type: :int
          attr :a_symbol, type: :symbol
        end
        define :test
        test :t do
          jaba_input.a_bool.must_equal(true)
          jaba_input.a_string.must_equal('str')
          jaba_input.string_array.must_equal(['a', 'b', 'c'])
          jaba_input.an_int.must_equal(1)
          jaba_input.a_symbol.must_equal(:symbol)
        end
      end
    end

  end

end
