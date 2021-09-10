# frozen_string_literal: true

module JABA

  class TestAttributeDefinition < JabaTest

    it 'accepts a string or a symbol as id' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagL)}: '123' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'." do
        jaba(barebones: true) do
          type :test do
            attr 123 # tagL
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
    
    it 'does not require a block to be supplied' do
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
    
    it 'detects duplicate attribute ids' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagQ)}: 'a' attribute multiply defined in 'test'. See previous at #{src_loc(__FILE__, :tagV)}." do
        jaba(barebones: true) do
          type :test do
            attr :a # tagV
            attr :a # tagQ
          end
        end
      end
    end

    it 'checks for invalid attribute types' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagY)}: 'not_a_type' attribute type is undefined.", ignore_rest: true do
        jaba(barebones: true) do
          type :test do
            attr :a, type: :not_a_type # tagY
          end
        end
      end
    end

    it 'checks for duplicate flags' do
      assert_jaba_warn("Duplicate flag ':read_only' specified", __FILE__, 'tagH') do
        jaba(barebones: true) do
          type :test do
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
      assert_jaba_warn("Duplicate flag option ':option' specified in ':a' attribute", __FILE__, 'tagD') do
        jaba(barebones: true) do
          type :test do
            attr :a do
              flag_options :option, :option # tagD
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

    it 'checks for invalid flags' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagE)}: ':invalid' is an invalid flag.", ignore_rest: true do
        jaba(barebones: true) do
          type :test do
            attr :a do
              flags :invalid # tagE
            end
          end
        end
      end  
    end

    it 'enforces max title length' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagF)}: Title must be 100 characters or less but was 166." do
        jaba(barebones: true) do
          type :test do
            attr :a do
              title 'This title exceeds the max attribute title length that Jaba allows. If titles were allowed to be this long it would look bad in command line help and reference manual' # tagF
            end
          end
        end
      end
    end

    it 'supports supplying defaults in block form' do
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

    it 'fails if default block references an unset attribute that does not have a default block' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagP)}: Cannot read uninitialised 't.a' attribute - it might need a default value.",
                        trace: [__FILE__, :tagC, __FILE__, :tagK] do
        jaba(barebones: true) do
          type :test do
            attr :a
            attr :b do
              default do
                "#{a.upcase}" # tagP
              end
            end
            attr :c do
              default do
                b # tagC
              end
            end
            attr :d
          end
          test :t do
            d c # tagK
          end
        end
      end
    end

    it 'fails if non-block default value trys to reference another attribute' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagZ)}: 'b.a' undefined. Are you setting default in terms of another attribute? If so block form must be used." do
        jaba(barebones: true) do
          type :test do
            attr :a
              #default :b
            attr :b do
              default "#{a.upcase}" # tagZ
            end
          end
          test :t do
            b :c
          end
        end
      end
    end
    # TODO: also check for circularity in default blocks
    
    it 'supports specifying a validator' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tags)}: 't.a' attribute invalid: Val must not be 2.", trace: [__FILE__, :tagS] do
        jaba(barebones: true) do
          type :test do
            attr :a do
              validate do |val|
                fail "Val must not be 2" if val == 2 # tags
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagJ)}: Flag options must be specified as symbols, eg :option." do
        jaba(barebones: true) do
          type :test do
            attr :a do
              flag_options 'a' # tagJ
            end
          end
        end
      end
    end

    it 'ensures value options are symbols' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagW)}: In ':a' attribute value_option id must be specified as a symbol, eg :option." do
        jaba(barebones: true) do
          type :test do
            attr :a do
              value_option 'a' # tagW
            end
          end
        end
      end
    end

    it 'supports specifying valid value options' do
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagA)}: Invalid value option ':undefined'. Valid ':a' array attribute options: [:group, :condition]" do
        jaba(barebones: true) do
          type :test do
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagB)}: Invalid value option ':undefined' - no options defined in ':a' array attribute." do
        jaba(barebones: true) do
          type :test do
            attr_array :a
          end
          test :t do
            a [1], undefined: :a # tagB
          end
        end
      end
    end
    
    it 'supports flagging value options as required' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagI)}: When setting 't.a' hash attribute 'group' option requires a value." do
        jaba(barebones: true) do
          type :test do
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagX)}: When setting 't.a' hash attribute invalid value ':d' passed to ':group' option. Valid values: [:a, :b, :c]" do
        jaba(barebones: true) do
          type :test do
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
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagO)}: When setting 't.a' hash attribute 'group' option requires a value. Valid values are [:a, :b, :c]" do
        jaba(barebones: true) do
          type :test do
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
