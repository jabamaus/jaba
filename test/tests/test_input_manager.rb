class TestInputManager < JabaTest

  # TODO: test specifying 2 commands in a row is a failure
  # TODO: test unrecognised cmd
  # TODO: test cmd is a symbol id
  it 'supports commands' do
    assert_output 'gen' do # default cmd
      jaba(barebones: true, argv: []) do
        type :test do
          plugin :test do
            def generate
              print services.cmd
            end
          end
        end
      end
    end
    assert_output 'cmd1' do
      jaba(barebones: true, argv: ['cmd1']) do
        type :test do
          plugin :test do
            def init
              services.register_cmd(:cmd1, help: 'cmd1 help')
            end
            def generate
              print services.cmd
            end
          end
        end
      end
    end
  end

  # TODO: should duplicate array options be allowed?
  it 'detects duplicate options' do
  end

  it 'handles unknown options' do
    assert_jaba_error "'gen' command does not support --unknown option", trace: nil do
      jaba(barebones: true, argv: ['--unknown']) # long form
    end
    assert_jaba_error "'gen' command does not support -Z option", trace: nil do
      jaba(barebones: true, argv: ['-Z']) # short form
    end
    # everything after -- is ignored
    op = jaba(barebones: true, argv: ['gen', '--', 'ignore', 'after', '--'])
    op[:services].input_manager.passthru_args.must_equal ['ignore', 'after', '--']
  end

  it 'supports value options' do
    assert_output 'tested' do
      jaba(barebones: true, argv: ['--value-opt', 'value']) do
        type :test do
          plugin :test do
            def init
              services.register_option('--value-opt', help: 'value opt', type: :value)
            end
            def generate
              services.cmd_option_specified?(:gen, '--value-opt').must_equal(true)
              services.cmd_option_value(:gen, '--value-opt').must_equal('value')
              print 'tested'
            end
          end
        end
      end
    end
    
    # test that values can be anything, even something that looks like an option (unless it is actually an option)
    #
    assert_output 'gen --value-opt=--value' do
      jaba(barebones: true, argv: ['--value-opt', '--value']) do
        type :test_im
      end
    end
    assert_raises JabaError  do
      jaba(barebones: true, argv: ['--value-opt']) do
        type :test_im
      end
    end.message.must_equal("-v [--value-opt] expects a value")
    # TODO: check that only one value supplied
  end

  it 'supports array options' do
    assert_output 'gen --array-opt=["e1", "e2", "e3"]' do
      jaba(barebones: true, argv: ['--array-opt', 'e1', 'e2', 'e3']) do
        type :test_im
      end
    end
    # test that values can be anything, even something that looks like an option (unless it is actually an option)
    #
    assert_output 'gen --array-opt=["--e1", "--e2", "--e3"]' do
      jaba(barebones: true, argv: ['--array-opt', '--e1', '--e2', '--e3']) do
        type :test_im
      end
    end
    assert_raises JabaError do
      jaba(barebones: true, argv: ['--array-opt']) do
        type :test_im
      end
    end.message.must_equal("-a [--array-opt] expects 1 or more values")
  end

  # TODO: check failure cases, eg when no value/s provided
  it 'can populate globals from command line' do
    jaba(barebones: true, argv: ['-D', 'bool', 'true']) do
      open_type :globals do
        attr :bool, type: :bool
      end
      type :test
      test :t do
        globals.bool.must_equal(true)
      end
    end
    jaba(argv: [
      '-D', 'bool1', 'true',
      '-D', 'bool2=false',
      '-D', 'a_string', 'str',
      '-D', 'an_int', '1',
      '-D', 'a_symbol=symbol',
      '-D', 'string_array', 'a', 'b', 'c',
      '-D', 'string_array_with_default', 'd,e,f',
      '--define', 'hash1', 'key1=value1', 'key2', '=value2', '-D', 'hash1', 'key3', 'value3=',
      '--define', 'hash2', 'key1', 'value1', 'key2=value2', '-D','hash2', 'key3', 'value3'
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
