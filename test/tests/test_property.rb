# frozen_string_literal: true

module JABA

  class PropertyContainer
    include PropertyMethods

    def initialize
      @services = Services.new
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

    it 'disallows passing array to non-array property' do
      
    end

    it 'can set single value properties' do
      
    end
    
    it 'appends single values or arrays to array properties' do
      pc = PropertyContainer.new
      pc.define_array_property(:a)
      pc.get_property(:a).must_equal []
      pc.set_property(:a, 1)
      pc.get_property(:a).must_equal [1]
      pc.set_property(:a, [2, 3])
      pc.get_property(:a).must_equal [1, 2, 3]
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

  end

end
