# frozen_string_literal: true

module JABA

  class TestAttributeDefinition < JabaTest

    it 'accepts a string or a symbol' do
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
          attr :b
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
            define_property :d, []
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
      check_fail "'undefined' property not defined", trace: [__FILE__, 'tagZ'] do
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

    it 'ensures keyval options are symbols' do
      check_fail 'Keyval options must be specified as symbols, eg :option', trace: [__FILE__, 'tagW'] do
        jaba do
          define :test do
            attr :a do
              keyval_options 'a' # tagW
            end
          end
        end
      end
    end

    it 'supports specifying valid key value options' do
      jaba do
        define :test do
          attr_array :a do
            keyval_options :group, :condition
          end
        end
        test :t do
          a 1, group: :a
          a 2, condition: :b
        end
      end
      check_fail 'Invalid keyval option \'undefined\'. Valid keys are [:group, :condition]', trace: [__FILE__, 'tagA'] do
        jaba do
          define :test do
            attr_array :a do
              keyval_options :group, :condition
            end
          end
          test :t do
            a 1, undefined: :a # tagA
          end
        end
      end
    end
    
  end

end
