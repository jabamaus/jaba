jtest 'allows inclusion of shared definitions in any object' do
  jaba(barebones: true) do
    shared :attr_setup do
      flags :no_sort
    end
    
    shared :attrs do
      attr_array :a do
        include :attr_setup
      end
    end
    type :test do
      include :attrs
    end
    test :t do
      a [3, 2, 1]
      a.must_equal [3, 2, 1]
    end
  end

  # check that all types support include directive
  #
  [:workspace, :category, :type].each do |type|
    assert_jaba_error "Error at #{src_loc('A290F56B')}: Included.", trace: [__FILE__, '82CB1E68'], hint: "When processing '#{type}'" do
      jaba do
        shared :a do
          fail 'Included' # A290F56B
        end
        __send__(type, :t) do
          include :a # 82CB1E68
        end
      end
    end
  end
end

jtest 'fails if shared definition does not exist' do
  assert_jaba_error "Error at #{src_loc('6E431814')}: shared definition ':b' not defined." do
    jaba(barebones: true) do
      shared :a do
      end
      type :test
      test :c do
        include :b # 6E431814
      end
    end
  end
end

jtest 'supports passing keyword args to shared definitions' do
  jaba(barebones: true) do
    shared :a do |arg1:, arg2: nil, arg3: 'f'|
      c "#{arg1}#{arg2}#{arg3}"
    end
    type :test do
      attr :c
    end
    test :t do
      include :a, arg1: 'd', arg3: 'e'
      c.must_equal('de')
    end
  end
end

jtest 'can chain includes' do
end
