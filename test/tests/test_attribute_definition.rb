# frozen_string_literal: true

module JABA

  class TestAttributeDefinition < JabaTest

    it 'accepts a string or a symbol as id' do
      check_fail '\'123\' is an invalid id', trace: [__FILE__, 'tagL'] do
        jaba do
          define :test do
            attr 123 # tagL
          end
        end
      end
      jaba do
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
      jaba do
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
      check_fail "'a' attribute multiply defined", trace: [__FILE__, 'tagQ'] do
        jaba do
          define :test do
            attr :a
            attr :a # tagQ
          end
        end
      end
    end

    it 'checks for duplicate flags' do
      check_warn("Duplicate flag ':read_only' specified", __FILE__, 'tagH') do
        jaba do
          define :test do
            attr :a do
              flags :read_only, :read_only # tagH
            end
          end
          test :t do
            generate do
              get_attr(:a).attr_def.get_property(:flags).must_equal [:read_only]
            end
          end
        end
      end
    end

    it 'checks for duplicate flag options' do
      check_warn("Duplicate flag option ':export' specified", __FILE__, 'tagD') do
        jaba do
          define :test do
            attr :a do
              flag_options :export, :export # tagD
            end
          end
          test :t do
            generate do
              get_attr(:a).attr_def.get_property(:flag_options).must_equal [:export]
            end
          end
        end
      end
    end

    it 'checks for invalid flags' do
      check_fail "':invalid' is an invalid flag", trace: [__FILE__, 'tagE'] do
        jaba do
          define :test do
            attr :a do
              flags :invalid # tagE
            end
          end
        end
      end  
    end

    it 'supports adding properties' do
      jaba do
        define :test do
          attr :a do
            define_property :b, 'b'
            define_property :c, 1
            define_array_property :d
            define_property :e
            define_property :f do
            end
            b.must_equal('b')
            c.must_equal(1)
            d.must_equal([])
            e.must_be_nil
            b 'c'
            c 2
            d [:d, :e]
            e :g
            b.must_equal('c')
            c.must_equal(2)
            d.must_equal [:d, :e]
            d [:f]
            d :g
            d.must_equal [:d, :e, :f, :g]
            e.must_equal(:g)
          end
        end
      end
    end
    
    it 'detects multiply defined properties' do
      check_fail "'a' property multiply defined", trace: [__FILE__, 'tagR'] do
        jaba do
          define :test do
            attr :a do
              define_property :a
              define_property :a # tagR
            end
          end
        end
      end
    end

    it 'fails if property does not exist' do
      check_fail "Failed to set undefined 'undefined' property", trace: [__FILE__, 'tagZ'] do
        jaba do
          define :test do
            attr :a do
              undefined 1 # tagZ
            end
          end
        end
      end
    end

    it 'supports supplying defaults in block form' do
      jaba do
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
      check_fail "Cannot read uninitialised 'a' attribute", trace: [__FILE__, 'tagP'] do
        jaba do
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
      check_fail "'a' attribute failed validation: Val must not be 2", trace: [__FILE__, 'tagT', __FILE__, 'tagS'] do
        jaba do
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
      check_fail 'Flag options must be specified as symbols, eg :option', trace: [__FILE__, 'tagJ'] do
        jaba do
          define :test do
            attr :a do
              flag_options 'a' # tagJ
            end
          end
        end
      end
    end

    it 'ensures value options are symbols' do
      check_fail 'value_option id must be specified as a symbol, eg :option', trace: [__FILE__, 'tagW'] do
        jaba do
          define :test do
            attr :a do
              value_option 'a' # tagW
            end
          end
        end
      end
    end

    it 'supports specifying valid value options' do
      jaba do
        define :test do
          attr_array :a do
            value_option :group
            value_option :condition
          end
        end
        test :t do
          a 1, group: :a
          a 2, condition: :b
        end
      end
      check_fail 'Invalid value option \':undefined\'. Valid options: [:group, :condition]', trace: [__FILE__, 'tagA'] do
        jaba do
          define :test do
            attr_array :a do
              value_option :group
              value_option :condition
            end
          end
          test :t do
            a 1, undefined: :a # tagA
          end
        end
      end
      check_fail 'Invalid value option \':undefined\' - no options defined', trace: [__FILE__, 'tagB'] do
        jaba do
          define :test do
            attr_array :a
          end
          test :t do
            a 1, undefined: :a # tagB
          end
        end
      end
    end
    
    it 'supports flagging value options as required' do
      check_fail "'group' option requires a value", trace: [__FILE__, 'tagI'] do
        jaba do
          define :test do
            attr_hash :a do
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
      check_fail "Invalid value ':d' passed to ':group' option. Valid values: [:a, :b, :c]", trace: [__FILE__, 'tagX'] do
        jaba do
          define :test do
            attr_hash :a do
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
      check_fail "'group' option requires a value. Valid values are [:a, :b, :c]", trace: [__FILE__, 'tagO'] do
        jaba do
          define :test do
            attr_hash :a do
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
