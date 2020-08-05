# frozen_string_literal: true

module JABA

  class Test_imGenerator < Generator
    def init
      register_cmdline_option('--value-opt', short: '-v', help: 'value opt', var: :value_opt, type: :value)
      register_cmdline_option('--array-opt', short: '-a', help: 'array opt', var: :array_opt, type: :array)
    end

    def generate
      print services.input.value_opt if services.input.value_opt
      print services.input.array_opt if !services.input.array_opt.empty?
    end
  end

  class TestInputManager < JabaTest

    # TODO: should duplicate array options be allowed?
    it 'detects duplicate options' do
      #check_fail '--dry-run specified more than once' do
        #jaba(barebones: true, argv: ['--dry-run', '--dry-run'])
      #end
    end

    it 'detects unknown options' do
      check_fail "--unknown option not recognised", exception: CommandLineUsageError do
        jaba(barebones: true, argv: ['--unknown'])
      end
      check_fail "-Z option not recognised", exception: CommandLineUsageError do
        jaba(barebones: true, argv: ['-Z'])
      end
    end

    it 'supports value options' do
      assert_output 'value' do
        jaba(barebones: true, argv: ['--value-opt', 'value']) do
          define :test_im
        end
      end
      
      # test that values can be anything, even something that looks like an option (unless it is actually an option)
      #
      assert_output '--value' do
        jaba(barebones: true, argv: ['--value-opt', '--value']) do
          define :test_im
        end
      end
      check_fail "-v [--value-opt] expects a value", exception: CommandLineUsageError do
        jaba(barebones: true, argv: ['--value-opt']) do
          define :test_im
        end
      end
    end

    it 'supports array options' do
      assert_output '["e1", "e2", "e3"]' do
        jaba(barebones: true, argv: ['--array-opt', 'e1', 'e2', 'e3']) do
          define :test_im
        end
      end
      # test that values can be anything, even something that looks like an option (unless it is actually an option)
      #
      assert_output '["--e1", "--e2", "--e3"]' do
        jaba(barebones: true, argv: ['--array-opt', '--e1', '--e2', '--e3']) do
          define :test_im
        end
      end
      check_fail "-a [--array-opt] expects 1 or more values", exception: CommandLineUsageError do
        jaba(barebones: true, argv: ['--array-opt']) do
          define :test_im
        end
      end
    end

    # TODO: check failure cases, eg when no value/s provided
    it 'can populate globals from command line' do
      jaba(barebones: true, argv: ['-Dbool']) do
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
        '--define', 'hash1', 'key1', 'value1', 'key2', 'value2', '-Dhash1', 'key3', 'value3',
        '--define', 'hash2', 'key1', 'value1', 'key2', 'value2', '-Dhash2', 'key3', 'value3'
        ]) do
        open_type :globals do
          attr :bool1, type: :bool
          attr :bool2, type: :bool
          attr :bool3, type: :bool
          attr :a_string, type: :string
          attr_array :string_array, type: :string
          attr :an_int, type: :int
          attr :a_symbol, type: :symbol
          attr_hash :hash1, key_type: :symbol, type: :string
          attr_hash :hash2, key_type: :string, type: :symbol
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
          globals.hash1.must_equal({key1: 'value1', key2: 'value2', key3: 'value3'})
          globals.hash2.must_equal({'key1' => :value1, 'key2' => :value2, 'key3' => :value3})
        end
      end
    end

  end

end
