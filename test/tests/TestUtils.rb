module JABA
  
class TestUtils < JabaTestCase
  
  describe 'Hash' do
  
    it 'supports push_value' do
      {}.push_value(:a, :b).must_equal({:a => [:b]})
      {}.push_value(:a, [:b]).must_equal({:a => [:b]})
      {}.push_value(:a, [:b, :c]).must_equal({:a => [:b, :c]})
      {:a => []}.push_value(:a, :b).must_equal({:a => [:b]})
      {:a => [:b]}.push_value(:a, :c).must_equal({:a => [:b, :c]})
      {:a => [:b]}.push_value(:a, [:c]).must_equal({:a => [:b, :c]})
      {:a => [:b, :c]}.push_value(:a, [:d]).must_equal({:a => [:b, :c, :d]})
      {:a => [:b, :c]}.push_value(:a, :d, clear: true).must_equal({:a => [:d]})
      {:a => [:b, :c]}.push_value(:a, [:d], clear: true).must_equal({:a => [:d]})
    end
    
  end
  
  describe 'Hooks' do
    
    it 'implements hook_defined?' do
      h = Hooks.new
      h.hook_defined?(:a).must_equal(false)
      h.define_hook(:a) {}
      h.hook_defined?(:a).must_equal(true)
    end
    
    it 'fails if hook undefined' do
      assert_raises do
        h = Hooks.new
        h.call_hook(:undefined)
      end.message.must_equal("'undefined' hook undefined")
    end
    
    it 'can call a single hook and return a value' do
      s = ''
      h = Hooks.new
      h.define_hook(:test) do
        self.must_equal(h)
        s << 'a'
        0
      end
      
      h.call_hook(:test).must_equal(0)
      s.must_equal('a')
    end
    
    it 'can call multiple hooks' do
      s = ''
      h = Hooks.new
      h.define_hook(:test) do
        self.must_equal(h)
        s << 'a'
        1
      end
      h.define_hook(:test) do
        self.must_equal(h)
        s << 'b'
        2
      end
      h.define_hook(:test) do
        self.must_equal(h)
        s << 'c'
        3
      end      
      h.call_hook(:test).must_equal(3)
      s.must_equal('abc')
    end
    
    it 'accepts arguments' do
      s = ''
      h = Hooks.new
      h.define_hook(:test) do |a, b, c|
        self.must_equal(h)
        a.must_equal('a')
        b.must_equal('b')
        c.must_equal('c')
        s << a << b << c
        false
      end
      h.define_hook(:test) do |a, b, c|
        self.must_equal(h)
        a.must_equal('a')
        b.must_equal('b')
        c.must_equal('c')
        s << c << b << a
        true
      end
      h.call_hook(:test, 'a', 'b', 'c').must_equal(true)
      s.must_equal('abccba')
    end
    
    it 'can execute against an arbitrary object' do
      s = ''
      h = Hooks.new
      h.define_hook(:test) do |a, b, c|
        self.must_equal(s)
        self << a << b << c
        0
      end
      
      h.call_hook(:test, 'a', 'b', 'c', receiver: s).must_equal(0)
      s.must_equal('abc')
    end

    it 'can override existing hooks' do
      s = ''
      h = Hooks.new
      h.define_hook(:test) do
        raise 'not called'
      end
      h.define_hook(:test, override: true) do
        raise 'not called'
      end
      h.define_hook(:test, override: true) do
        self.must_equal(h)
        s << 'c'
        3
      end      
      h.call_hook(:test).must_equal(3)
      s.must_equal('c')
    end
    
  end

end
  
end
