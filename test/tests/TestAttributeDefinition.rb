module JABA

class TestAttributeDefinition < JabaTest

  it 'requires attribute id to be a symbol' do
    check_fails('\'attr\' attribute id must be specified as a symbol', trace: [__FILE__, '# tag1']) do
      jaba do
        define :test do
          attr 'attr' do # tag1
          end
        end
      end
    end
  end
  
  it 'requires a block to be supplied' do
    check_fails("'b' attribute requires a block", trace: [__FILE__, '# tag2']) do
      jaba do
        define :test do
          attr :b # tag2
        end
      end
    end
  end
  
  it 'detects duplicate attribute ids' do
    check_fails("'a' attribute multiply defined", trace: [__FILE__, '# tag3']) do
      jaba do
        define :test do
          attr :a do
          end
          attr :a do # tag3
          end
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
    check_fails("", trace: [__FILE__, '# tag4']) do
      jaba do
        define :test do
          attr :a do
            undefined 1 # tag4
          end
        end
      end
    end
  end
    
end

end
