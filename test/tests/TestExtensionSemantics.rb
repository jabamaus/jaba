module JABA

class TestExtensionSemantics < JabaTest

  it 'supports creating new node types' do
    jaba do
      define :test do
        attr :a do
        end
      end
      test :t do
        a 'b'
        a.must_equal('b')
      end
    end
  end

  it 'fails if try to extend undefined type' do
    check_fails("'undefined' has not been defined", trace: [__FILE__, '# tag1']) do
      jaba do
        extend :undefined do # tag1
        end
      end
    end
  end
  
  it 'supports adding an attribute to core types' do
    jaba do
      extend :project do
        attr :a do
        end
      end
      
      project :p do
        platforms [:win32]
        targets [:t]
        a 'val'
        a.must_equal('val')
      end
    end
  end

  # TODO: extend
  it 'supports defining new attribute types' do
    check_fails("'b' attribute failed validation: Invalid", trace: [__FILE__, "raise 'invalid'", __FILE__, '# tag2']) do 
      jaba do
        attr_type :a do
          validate do |val|
            raise 'invalid'
          end
        end
        define :test do
          attr :b, type: :a do
          end
        end
        test :t do
          b 'c' # tag2
        end
      end
    end
  end
  
  it 'detects usage of undefined attribute types' do
    check_fails(/'undefined' attribute type is undefined. Valid types: \[.*?\]/, trace: [__FILE__, '# tag3']) do
      jaba do
        define :a do
          attr :b, type: :undefined do # tag3
          end
        end
      end
    end
  end
  
  it 'supports definining new attribute flags' do
    jaba do
      attr_flag :foo
      attr_flag :bar
      
      extend :project do
        attr :a do
          flags :foo, :bar
        end
      end
    end
    # TODO: test something
  end
=begin
  # TODO: check only :container attr can have children
  it 'can build a tree of nodes' do
    jaba do
      define :test do
        attr :root do
        end
        attr :skus do
          type :container, child_type: :sku
          attr :name do
          end
        end
        
      end
      test :t do
        root 1
        skus [:a, :b, :c]
        case sku
        when :a
          name 'sku_a'
        when :b
          name 'sku_b'
        when :c
          name 'sku_c'
        end
        generate do
          root.must_equal 1
          sku_obj_a = skus[0]
          sku_obj_b = skus[1]
          sku_obj_c = skus[2]
          sku_obj_a.sku.must_equal(:a)
          sku_obj_b.sku.must_equal(:b)
          sku_obj_c.sku.must_equal(:c)
          sku_obj_a.name.must_equal('sku_a')
          sku_obj_b.name.must_equal('sku_b')
          sku_obj_c.name.must_equal('sku_c')
        end
      end
    end
  end
=end
end

end
