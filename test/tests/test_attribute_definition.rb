# frozen_string_literal: true

module JABA

  class TestAttributeDefinition < JabaTest

    it 'accepts a string or a symbol as id' do
      check_fail '\'123\' is an invalid id', line: [__FILE__, 'tagL'] do
        jaba(barebones: true) do
          define :test do
            attr 123 # tagL
          end
        end
      end
      jaba(barebones: true) do
        define :test do
          attr 'attr1' do
            default 1
          end
          attr :attr2 do
            default 2
          end
        end
        test :t do
          attr1.must_equal 1
          attr2.must_equal 2
        end
      end
    end
    
    it 'does not require a block to be supplied' do
      jaba(barebones: true) do
        define :test do
          attr :a
        end
        test :t do
          a 1
          a.must_equal 1
        end
      end
    end
    
    it 'detects duplicate attribute ids' do
      check_fail "'a' attribute multiply defined", line: [__FILE__, 'tagQ'] do
        jaba(barebones: true) do
          define :test do
            attr :a
            attr :a # tagQ
          end
        end
      end
    end

    it 'checks for invalid attribute types' do
      check_fail "'not_a_type' attribute type is undefined", line: [__FILE__, 'tagY'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :not_a_type # tagY
          end
        end
      end
    end

    it 'checks for duplicate flags' do
      check_warn("Duplicate flag ':read_only' specified", __FILE__, 'tagH') do
        jaba(barebones: true) do
          define :test do
            attr :a do
              flags :read_only, :read_only # tagH
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

    it 'checks for duplicate flag options' do
      check_warn("Duplicate flag option ':export' specified in 'a' attribute", __FILE__, 'tagD') do
        jaba(barebones: true) do
          define :test do
            attr :a do
              flag_options :export, :export # tagD
            end
          end
          test :t do
            generate do
              get_attr(:a).attr_def.flag_options.must_equal [:export]
            end
          end
        end
      end
    end

    it 'checks for invalid flags' do
      check_fail "':invalid' is an invalid flag. Valid flags: [:allow_dupes, :base_on_cwd, :expose, :no_check_exist, :no_sort, :read_only, :required]", line: [__FILE__, 'tagE'] do
        jaba(barebones: true) do
          define :test do
            attr :a do
              flags :invalid # tagE
            end
          end
        end
      end  
    end

    it 'enforces max title length' do
      check_fail "Title must be 100 characters or less but was 166", line: [__FILE__, 'tagF'] do
        jaba(barebones: true) do
          define :test do
            attr :a do
              title 'This title exceeds the max attribute title length that Jaba allows. If titles were allowed to be this long it would look bad in command line help and reference manual' # tagF
            end
          end
        end
      end
    end

    it 'supports supplying defaults in block form' do
      jaba(barebones: true) do
        define :test do
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

    it 'fails if default block references an unset attribute that does not have a default block' do
      check_fail "Cannot read uninitialised 't.a' attribute", line: [__FILE__, 'tagP'] do
        jaba(barebones: true) do
          define :test do
            attr :a
            attr :b do
              default do
                "#{a.upcase}" # tagP
              end
            end
            attr :c do
              default do
                b
              end
            end
            attr :d
          end
          test :t do
            d c
          end
        end
      end
    end

    # TODO: also check for circularity in default blocks
    
    it 'supports specifying a validator' do
      check_fail "'t.a' attribute failed validation: Val must not be 2. See #{__FILE__}:#{find_line_number(__FILE__, 'tagT')}",
         line: [__FILE__, 'tagS'] do
        jaba(barebones: true) do
          define :test do
            attr :a do
              validate do |val|
                fail "Val must not be 2" if val == 2 # tagT
              end
            end
          end
          test :t do
            a 1
            a 2 # tagS
          end
        end
      end
    end

    it 'ensures flag options are symbols' do
      check_fail 'Flag options must be specified as symbols, eg :option', line: [__FILE__, 'tagJ'] do
        jaba(barebones: true) do
          define :test do
            attr :a do
              flag_options 'a' # tagJ
            end
          end
        end
      end
    end

    it 'ensures value options are symbols' do
      check_fail 'value_option id must be specified as a symbol, eg :option', line: [__FILE__, 'tagW'] do
        jaba(barebones: true) do
          define :test do
            attr :a do
              value_option 'a' # tagW
            end
          end
        end
      end
    end

    it 'supports specifying valid value options' do
      jaba(barebones: true) do
        define :test do
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
      check_fail "Invalid value option ':undefined'. Valid 'a' array attribute options: [:group, :condition]", line: [__FILE__, 'tagA'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a do
              value_option :group
              value_option :condition
            end
          end
          test :t do
            a [1], undefined: :a # tagA
          end
        end
      end
      check_fail "Invalid value option ':undefined' - no options defined in 'a' array attribute", line: [__FILE__, 'tagB'] do
        jaba(barebones: true) do
          define :test do
            attr_array :a
          end
          test :t do
            a [1], undefined: :a # tagB
          end
        end
      end
    end
    
    it 'supports flagging value options as required' do
      check_fail "'group' option requires a value", line: [__FILE__, 'tagI'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol do
              value_option :group, required: true
            end
          end
          test :t do
            a :k, :v # tagI
          end      
        end
      end
    end

    it 'supports specifying a valid set of values for value option' do
      check_fail "In 't.a' hash attribute invalid value ':d' passed to ':group' option. Valid values: [:a, :b, :c]", line: [__FILE__, 'tagX'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol do
              value_option :group, items: [:a, :b, :c]
            end
          end
          test :t do
            a :k, :v, group: :d # tagX
          end      
        end
      end
    end

    it 'supports specifying a valid set of values for required value option' do
      check_fail "'group' option requires a value. Valid values are [:a, :b, :c]", line: [__FILE__, 'tagO'] do
        jaba(barebones: true) do
          define :test do
            attr_hash :a, key_type: :symbol do
              value_option :group, required: true, items: [:a, :b, :c]
            end
          end
          test :t do
            a :k, :v # tagO
          end      
        end
      end
    end

  end

end
