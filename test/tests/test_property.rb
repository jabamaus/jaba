# frozen_string_literal: true

module JABA

  using JABACoreExt

  class PropertyContainer
    include PropertyMethods

    def initialize(on_prop_set: false)
      super()
      @services = Services.new
      @on_prop_set = on_prop_set
    end

    def on_property_set(id, new_val)
      return if !@on_prop_set
      if new_val.proc?
        puts "#{id} -> block"
      else
        puts "#{id} -> #{new_val}"
      end
    end
  end

  class TestProperty < JabaTest

    it 'can define a property with or without default' do
      pc = PropertyContainer.new
      pc.define_property(:a)
      pc.get_property(:a).must_be_nil
      pc.define_property(:b, 1)
      pc.get_property(:b).must_equal(1)
    end

    it 'can define an array property with or without default' do
      pc = PropertyContainer.new
      pc.define_array_property(:a)
      pc.get_property(:a).must_equal []
      pc.define_array_property(:b, [1, 2])
      pc.get_property(:b).must_equal [1, 2]
    end

    it 'can set single value properties' do
      pc = PropertyContainer.new
      pc.define_property(:a)
      pc.set_property(:a, 1)
      pc.get_property(:a).must_equal(1)
    end
    
    it 'appends single values or arrays to array properties' do
      pc = PropertyContainer.new
      pc.define_array_property(:a)
      pc.get_property(:a).must_equal []
      pc.set_property(:a, 1)
      pc.get_property(:a).must_equal [1]
      pc.set_property(:a, [2, 3])
      pc.get_property(:a).must_equal [1, 2, 3]
      pc.set_property(:a, [[4, 5], [6, 7]]) # gets flattened
      pc.get_property(:a).must_equal [1, 2, 3, 4, 5, 6, 7]
    end

    it 'fails if get undefined property' do
      e = assert_raises RuntimeError do
        pc = PropertyContainer.new
        pc.get_property(:a)
      end
      e.message.must_equal("'a' property not defined")
    end

    it 'fails if set undefined property' do
      e = assert_raises RuntimeError do
        pc = PropertyContainer.new
        pc.set_property(:a)
      end
      e.message.must_equal("'a' property not defined")
    end

    it 'fails if property multiply defined' do
      e = assert_raises RuntimeError do
        pc = PropertyContainer.new
        pc.define_property(:a)
        pc.define_property(:a)
      end
      e.message.must_equal("'a' property multiply defined")
      e = assert_raises RuntimeError do
        pc = PropertyContainer.new
        pc.define_array_property(:a)
        pc.define_array_property(:a)
      end
      e.message.must_equal("'a' property multiply defined")
      e = assert_raises RuntimeError do
        pc = PropertyContainer.new
        pc.define_property(:a)
        pc.define_array_property(:a)
      end
      e.message.must_equal("'a' property multiply defined")
    end

    it 'stays as either a single value or array' do
      pc = PropertyContainer.new
      pc.define_property(:a, 1)
      assert_raises RuntimeError do
        pc.set_property(:a, [1])
      end.message.must_equal("'a' property cannot accept an array")
      pc.define_property(:b)
      pc.set_property(:b, [1]) # allowed because b is nil
      pc.get_property(:b).must_equal [1]
      pc.set_property(:b, 2) # now appends because property has become an array
      pc.get_property(:b).must_equal [1, 2]
    end

    it 'supports blocks' do
      pc = PropertyContainer.new
      pc.define_property(:a)
      pc.set_property(:a) do
        print 'in block'
      end
      pc.get_property(:a).proc?.must_equal(true)
      pc.set_property(:a) do
        print 'in different block'
      end
      assert_output 'in different block' do
        pc.get_property(:a).call
      end
    end

    it 'calls on_property_set with incoming value' do
      assert_output "a -> 1\nb -> [2]\nb -> [3, 4]\nc -> block\n" do
        pc = PropertyContainer.new(on_prop_set: true)
        pc.define_property(:a)
        pc.set_property(:a, 1)
        pc.define_array_property(:b)
        pc.set_property(:b, 2)
        pc.set_property(:b, [3, 4])
        pc.define_property(:c)
        pc.set_property(:c) do
        end
      end
    end

  end

end
