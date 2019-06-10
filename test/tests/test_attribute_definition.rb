# frozen_string_literal: true

module JABA

  class TestAttributeDefinition < JabaTest

    it 'requires attribute id to be a symbol' do
      check_fail '\'attr\' attribute id must be specified as a symbol', trace: [__FILE__, '# tag1'] do
        jaba do
          define :test do
            attr 'attr' # tag1
          end
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
      check_fail "'a' attribute multiply defined", trace: [__FILE__, '# tag3'] do
        jaba do
          define :test do
            attr :a
            attr :a # tag3
          end
        end
      end
    end
    
    it 'supports adding properties' do
      jaba do
        define :test do
          attr :a do
            add_property :b, 'b'
            add_property :c, 1
            add_property :d, []
            add_property :e
            add_property :f do
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
      
    it 'fails if property does not exist' do
      check_fail '', trace: [__FILE__, '# tag4'] do # TODO: msg
        jaba do
          define :test do
            attr :a do
              undefined 1 # tag4
            end
          end
        end
      end
    end
    
    it 'supports supplying defaults in block form' do
      jaba do
        define :test do
          attr :a do
            default 1
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
          a.must_equal(1)
          b.must_equal('1_1')
          c.must_equal('1_1_2')
          b 3
          b.must_equal(3)
          c.must_equal('3_2')
          d.must_equal([1, 3, '3_2'])
        end
      end
    end
      
  end

end
