jtest 'accepts a string or a symbol as id' do
  assert_jaba_error "Error at #{src_loc('9D4E653B')}: '123' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'." do
    jaba(barebones: true) do
      type :test do
        attr 123 # 9D4E653B
      end
    end
  end
  jaba(barebones: true) do
    type :test do
      attr 'attr1' do
        default 1
      end
      attr :attr2 do
        default 2
      end
      attr :Attr3 # caps allowed
    end
    test :t do
      attr1.must_equal 1
      attr2.must_equal 2
    end
  end
end

jtest 'does not require a block to be supplied' do
  jaba(barebones: true) do
    type :test do
      attr :a
    end
    test :t do
      a 1
      a.must_equal 1
    end
  end
end

jtest 'detects duplicate attribute ids' do
  assert_jaba_error "Error at #{src_loc('B271B14C')}: 'a' attribute multiply defined in 'test'. See previous at #{src_loc('4771160D')}." do
    jaba(barebones: true) do
      type :test do
        attr :a # 4771160D
        attr :a # B271B14C
      end
    end
  end
end

jtest 'checks for invalid attribute types' do
  assert_jaba_error "Error at #{src_loc('7906A8F9')}: 'not_a_type' attribute type is undefined.", ignore_rest: true do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :not_a_type # 7906A8F9
      end
    end
  end
end

jtest 'checks for duplicate flags' do
  assert_jaba_warn("Duplicate flag ':read_only' specified", __FILE__, 'B18A2189') do
    jaba(barebones: true) do
      type :test do
        attr :a do
          flags :read_only, :read_only # B18A2189
        end
      end
      test :t do
        generate do
          get_attr(:a).attr_def.flags.must_equal [:read_only]
        end
      end
    end
  end
end

jtest 'checks for duplicate flag options' do
  assert_jaba_warn("Duplicate flag option ':option' specified in ':a' attribute", __FILE__, 'F879E2A5') do
    jaba(barebones: true) do
      type :test do
        attr :a do
          flag_options :option, :option # F879E2A5
        end
      end
      test :t do
        generate do
          get_attr(:a).attr_def.flag_options.must_equal [:option]
        end
      end
    end
  end
end

jtest 'checks for invalid flags' do
  assert_jaba_error "Error at #{src_loc('B4CBB5AC')}: ':invalid' is an invalid flag.", ignore_rest: true do
    jaba(barebones: true) do
      type :test do
        attr :a do
          flags :invalid # B4CBB5AC
        end
      end
    end
  end  
end

jtest 'enforces max title length' do
  assert_jaba_error "Error at #{src_loc('A1F17E96')}: Title must be 100 characters or less but was 166." do
    jaba(barebones: true) do
      type :test do
        attr :a do
          title 'This title exceeds the max attribute title length that Jaba allows. If titles were allowed to be this long it would look bad in command line help and reference manual' # A1F17E96
        end
      end
    end
  end
end

jtest 'supports supplying defaults in block form' do
  jaba(barebones: true) do
    type :test do
      attr :a do
        default '1'
      end
      attr :b do
        default {"#{a}_1"}
      end
      attr :c do
        default {"#{b}_2"}
      end
      attr_array :d do
        default {[a, b, c]}
      end
    end
    test :t do
      a.must_equal('1')
      b.must_equal('1_1')
      c.must_equal('1_1_2')
      b '3'
      b.must_equal('3')
      c.must_equal('3_2')
      d.must_equal(['1', '3', '3_2'])
    end
  end
end

jtest 'fails if default block references an unset attribute that does not have a default block' do
  assert_jaba_error "Error at #{src_loc('430F0FD5')}: Cannot read uninitialised 't.a' attribute - it might need a default value.",
                    trace: [__FILE__, '51AC7AED', __FILE__, '07807741'] do
    jaba(barebones: true) do
      type :test do
        attr :a
        attr :b do
          default do
            "#{a.upcase}" # 430F0FD5
          end
        end
        attr :c do
          default do
            b # 51AC7AED
          end
        end
        attr :d
      end
      test :t do
        d c # 07807741
      end
    end
  end
end

jtest 'fails if non-block default value tries to reference another attribute' do
  assert_jaba_error "Error at #{src_loc('57E75C16')}: 'b.a' undefined. Are you setting default in terms of another attribute? If so block form must be used." do
    jaba(barebones: true) do
      type :test do
        attr :a
        attr :b do
          default "#{a.upcase}" # 57E75C16
        end
      end
      test :t do
        b :c
      end
    end
  end
end
# TODO: also check for circularity in default blocks

jtest 'supports specifying a validator' do
  assert_jaba_error "Error at #{src_loc('249ADB7E')}: 't.a' attribute invalid: Val must not be 2.", trace: [__FILE__, '6E2D8DAC'] do
    jaba(barebones: true) do
      type :test do
        attr :a do
          validate do |val|
            fail "Val must not be 2" if val == 2 # 249ADB7E
          end
        end
        attr_array :b do
          validate do |val|
            fail "Val must not be 2" if val == 2
          end
        end
        attr_hash :c, key_type: :int do
          validate do |val|
            fail "Val must not be 2" if val == 2
          end
        end
      end
      test :t do
        a 1
        a 2 # 6E2D8DAC
        b [1]
        b [2]
        c 1, 1
        c 1, 2
      end
    end
  end
end

jtest 'ensures flag options are symbols' do
  assert_jaba_error "Error at #{src_loc('8EFEF2D3')}: Flag options must be specified as symbols, eg :option." do
    jaba(barebones: true) do
      type :test do
        attr :a do
          flag_options 'a' # 8EFEF2D3
        end
      end
    end
  end
end

jtest 'ensures value options are symbols' do
  assert_jaba_error "Error at #{src_loc('6248AA6B')}: In ':a' attribute value_option id must be specified as a symbol, eg :option." do
    jaba(barebones: true) do
      type :test do
        attr :a do
          value_option 'a' # 6248AA6B
        end
      end
    end
  end
end

jtest 'supports specifying valid value options' do
  jaba(barebones: true) do
    type :test do
      attr_array :a do
        value_option :group
        value_option :condition
      end
    end
    test :t do
      a [1], group: :a
      a [2], condition: :b
    end
  end
  assert_jaba_error "Error at #{src_loc('15EB072D')}: Invalid value option ':undefined'. Valid ':a' array attribute options: [:group, :condition]" do
    jaba(barebones: true) do
      type :test do
        attr_array :a do
          value_option :group
          value_option :condition
        end
      end
      test :t do
        a [1], undefined: :a # 15EB072D
      end
    end
  end
  assert_jaba_error "Error at #{src_loc('9D8FC17A')}: Invalid value option ':undefined' - no options defined in ':a' array attribute." do
    jaba(barebones: true) do
      type :test do
        attr_array :a
      end
      test :t do
        a [1], undefined: :a # 9D8FC17A
      end
    end
  end
end

jtest 'supports flagging value options as required' do
  assert_jaba_error "Error at #{src_loc('3A2B8168')}: When setting 't.a' hash attribute 'group' option requires a value." do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol do
          value_option :group, required: true
        end
      end
      test :t do
        a :k, :v # 3A2B8168
      end      
    end
  end
end

jtest 'supports specifying a valid set of values for value option' do
  assert_jaba_error "Error at #{src_loc('5114C7F9')}: When setting 't.a' hash attribute invalid value ':d' passed to ':group' option. Valid values: [:a, :b, :c]" do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol do
          value_option :group, items: [:a, :b, :c]
        end
      end
      test :t do
        a :k, :v, group: :d # 5114C7F9
      end      
    end
  end
end

jtest 'supports specifying a valid set of values for required value option' do
  assert_jaba_error "Error at #{src_loc('1526FED8')}: When setting 't.a' hash attribute 'group' option requires a value. Valid values are [:a, :b, :c]" do
    jaba(barebones: true) do
      type :test do
        attr_hash :a, key_type: :symbol do
          value_option :group, required: true, items: [:a, :b, :c]
        end
      end
      test :t do
        a :k, :v # 1526FED8
      end      
    end
  end
end

jtest 'can access globals when setting up attrs' do
  jaba(barebones: true) do
    open_type :globals do
      attr_array :some_extensions do
        default ['.a', '.b', '.c']
      end
    end
    type :test do
      attr :ext, type: :choice do
        items globals.some_extensions
        default '.a'
      end
    end
    test :t do
      ext.must_equal('.a')
      ext '.b'
      ext.must_equal('.b')
    end
  end
end
