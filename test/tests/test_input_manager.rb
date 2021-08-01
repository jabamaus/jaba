# frozen_string_literal: true

module JABA

  class Test_imGenerator < Generator
    def initialize(services)
      super
      # General options, available to all commands
      #
      register_cmdline_option('--value-opt', short: '-v', help: 'value opt', var: :value_opt, type: :value)
      register_cmdline_option('--array-opt', short: '-a', help: 'array opt', var: :array_opt, type: :array)

      register_cmdline_cmd(:cmd1, help: 'cmd1 help')
      register_cmdline_cmd(:cmd2, help: 'cmd2 help')
    end

    def generate
      i = services.input
      print i.value_opt if i.value_opt
      print i.array_opt if !i.array_opt.empty?
      if services.input_manager.cmd_specified?(:cmd1)
        print 'cmd1'
      end
    end
  end

  class TestInputManager < JabaTest

    it 'supports commands' do
      assert_output 'cmd1' do
        jaba(barebones: true, argv: ['cmd1']) do
          define :test_im
        end
      end
    end

    # TODO: should duplicate array options be allowed?
    it 'detects duplicate options' do
    end

    it 'detects unknown options' do
      assert_raises JabaError do
        jaba(barebones: true, argv: ['--unknown'])
      end.message.must_equal("--unknown option not recognised")
      assert_raises JabaError do
        jaba(barebones: true, argv: ['-Z'])
      end.message.must_equal("-Z option not recognised")
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
      assert_raises JabaError  do
        jaba(barebones: true, argv: ['--value-opt']) do
          define :test_im
        end
      end.message.must_equal("-v [--value-opt] expects a value")
      # TODO: check that only one value supplied
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
      assert_raises JabaError do
        jaba(barebones: true, argv: ['--array-opt']) do
          define :test_im
        end
      end.message.must_equal("-a [--array-opt] expects 1 or more values")
    end

    # TODO: check failure cases, eg when no value/s provided
    it 'can populate globals from command line' do
      jaba(barebones: true, argv: ['-D', 'bool', 'true']) do
        open_type :globals do
          attr :bool, type: :bool
        end
        define :test
        test :t do
          globals.bool.must_equal(true)
        end
      end
      jaba(argv: [
        '-D', 'bool1', 'true',
        '-D', 'bool2', 'false',
        '-D', 'a_string', 'str',
        '-D', 'an_int', '1',
        '-D', 'a_symbol', 'symbol',
        '-D', 'string_array', 'a', 'b', 'c',
        '-D', 'string_array_with_default', 'd', 'e', 'f',
        '--define', 'hash1', 'key1', 'value1', 'key2', 'value2', '-D', 'hash1', 'key3', 'value3',
        '--define', 'hash2', 'key1', 'value1', 'key2', 'value2', '-D','hash2', 'key3', 'value3'
        ]) do
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
        define :test
        test :t do
          globals.bool1.must_equal(true)
          globals.bool2.must_equal(false)
          globals.a_string.must_equal('str')
          globals.an_int.must_equal(1)
          globals.a_symbol.must_equal(:symbol)

          globals.string_array.must_equal(['a', 'b', 'c'])
          globals.string_array_with_default.must_equal(['a', 'b', 'c', 'd', 'e', 'f'])

          globals.hash1.must_equal({key1: 'value1', key2: 'value2', key3: 'value3'})
          globals.hash2.must_equal({'key1' => :value1, 'key2' => :value2, 'key3' => :value3})
        end
      end
    end

  end

end
