class PropertyContainer
  include JABA::PropertyMethods

  def initialize(on_prop_set: false)
    super()
    @on_prop_set = on_prop_set
    @ignore_next = false
  end

  def ignore_next
    @ignore_next = true
  end

  def pre_property_set(id, new_val)
    return if !@on_prop_set
    if @ignore_next
      @ignore_next = false
      return :ignore
    end
    if new_val.proc?
      puts "pre #{id}->block"
    else
      puts "pre #{id}->#{new_val}"
    end
  end

  def post_property_set(id, new_val)
    return if !@on_prop_set
    if new_val.proc?
      puts "post #{id}->block"
    else
      puts "post #{id}->#{new_val}"
    end
  end
end

jtest 'supports single value properties' do
  pc = PropertyContainer.new
  pc.define_single_property(:a)

  assert_jaba_error "'a' expects a single value but got '[1]'", trace: nil do
    pc.set_property(:a, [1])
  end

  assert_jaba_error "'a' expects a single value but got '{:a=>:b}'", trace: nil do
    pc.set_property(:a, {a: :b})
  end
  
  pc.set_property(:a, 1)
  pc.a.must_equal 1
  pc.get_property(:a).must_equal(1)
  pc.set_property(:a, 2)
  pc.a.must_equal(2)

  # It can store a block as value
  #
  pc.define_single_property(:b, store_block: true)
  pc.set_property(:b) do
    print 'can store block if flagged'
  end
  assert_output 'can store block if flagged' do
    pc.b.call
  end

  # It can take its value from block
  #
  pc.define_single_property(:c)
  pc.set_property(:c) do
    1
  end
  pc.c.must_equal(1)
  pc.set_property(:c) do
    2
  end
  pc.c.must_equal(2)
end

jtest 'supports array properties' do
  pc = PropertyContainer.new
  pc.define_array_property(:a)
  pc.a.must_equal []

  assert_jaba_error "'a' expects an array but got '{:a=>:b}'", trace: nil do
    pc.set_property(:a, {a: :b})
  end

  pc.set_property(:a, 1) # arrays accept single values
  pc.get_property(:a).must_equal [1]
  pc.set_property(:a, [2, 3])
  pc.a.must_equal [1, 2, 3]
  pc.set_property(:a, [[4, 5], [6, 7]]) # gets flattened
  pc.a.must_equal [1, 2, 3, 4, 5, 6, 7]

  # It can store a block as value
  #
  pc.define_array_property(:b, store_block: true)
  pc.set_property(:b) do
    print 'can store block if flagged'
  end
  assert_output 'can store block if flagged' do
    pc.b.call
  end

  # It can take its value from block
  #
  pc.define_array_property(:c)
  pc.set_property(:c) do
    [1, 2, 3]
  end
  pc.c.must_equal [1, 2, 3]
  pc.set_property(:c) do
    4
  end
  pc.c.must_equal [1, 2, 3, 4]
end

jtest 'supports hash properties' do
  pc = PropertyContainer.new
  pc.define_hash_property(:a)
  pc.a.must_equal({})

  assert_jaba_error "'a' expects a hash but got '1'", trace: nil do
    pc.set_property(:a, 1)
  end
  
  pc.set_property(:a, {a: :b})
  pc.a.must_equal({a: :b})
  pc.get_property(:a).must_equal({a: :b})
  pc.set_property(:a, {c: :d})
  pc.a.must_equal({a: :b, c: :d})

  # It can store a block as value
  #
  pc.define_hash_property(:b, store_block: true)
  pc.set_property(:b) do
    print 'can store block if flagged'
  end
  assert_output 'can store block if flagged' do
    pc.b.call
  end

  # It can take its value from block
  #
  pc.define_hash_property(:c)
  pc.set_property(:c) do
    {a: :b}
  end
  pc.c.must_equal({a: :b})
  pc.set_property(:c) do
    {c: :d}
  end
  pc.c.must_equal({a: :b, c: :d})
end

jtest 'supports block types' do
  pc = PropertyContainer.new
  pc.define_single_property(:a, type: :block)
  pc.set_property(:a) do
    print 'in block'
  end
  assert_output 'in block' do
    pc.a.call
  end
  pc.a.proc?.must_equal(true)
  pc.set_property(:a) do
    print 'in different block'
  end
  assert_output 'in different block' do
    pc.a.call
  end
  pc.set_property(:a, lambda{ print 'setting via lambda'})
  assert_output 'setting via lambda' do
    pc.a.call
  end
  assert_jaba_error 'Must provide a value or a block but not both', trace: nil do
    pc.set_property(:a, 1) do
    end
  end

  pc.define_array_property(:b, type: :block)
  pc.set_property(:b) do
    print 'in block[0]|'
  end
  pc.set_property(:b) do
    print 'in block[1]'
  end
  assert_output 'in block[0]|in block[1]' do
    pc.b.each(&:call)
  end

  pc.define_hash_property(:c, type: :block)
  pc.set_property(:c, :k0) do
    'in block[0]|'
  end
  pc.set_property(:c, :k1) do
    'in block[1]'
  end
  assert_output 'k0=>in block[0]|k1=>in block[1]' do
    pc.c.each do |key, block|
      print "#{key}=>#{block.call}"
    end
  end
end

jtest 'fails if property undefined' do
  pc = PropertyContainer.new
  assert_jaba_error "'a' property undefined", trace: nil do
    pc.set_property(:a)
  end
  assert_jaba_error "'a' property undefined", trace: nil do
    pc.get_property(:a)
  end
end

jtest 'fails if property multiply defined' do
  assert_jaba_error "'a' property multiply defined", trace: nil do
    pc = PropertyContainer.new
    pc.define_single_property(:a)
    pc.define_single_property(:a)
  end
  assert_jaba_error "'a' property multiply defined", trace: nil do
    pc = PropertyContainer.new
    pc.define_array_property(:a)
    pc.define_array_property(:a)
  end
  assert_jaba_error "'a' property multiply defined", trace: nil do
    pc = PropertyContainer.new
    pc.define_single_property(:a)
    pc.define_array_property(:a)
  end
end

jtest 'calls pre_property_set and post_property_set with incoming value' do
  assert_output %Q{pre a->1
post a->1
pre a->2
post a->2
pre b->2
post b->2
pre b->3
post b->3
pre b->4
post b->4
pre c->{:a=>:b}
post c->{:a=>:b}
pre c->{:c=>:d}
post c->{:c=>:d}
pre d->block
post d->block
} do
    pc = PropertyContainer.new(on_prop_set: true)
    pc.define_single_property(:a)
    pc.set_property(:a, 1)
    pc.set_property(:a) do
      2
    end
    pc.define_array_property(:b)
    pc.set_property(:b, [2])
    pc.ignore_next
    pc.set_property(:b, [5]) # Won't get set
    pc.set_property(:b) do
      [3, 4]
    end
    pc.define_hash_property(:c)
    pc.set_property(:c, {a: :b})
    pc.set_property(:c) do
      {c: :d}
    end
    pc.define_single_property(:d, type: :block) # doesn't call pre/post set for block properties
    pc.set_property(:d) do
    end
  end
end
