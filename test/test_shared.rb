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

jtest 'supports passing args to shared definitions' do
  jaba(barebones: true) do
    shared :a do |arg|
      c "#{arg}"
    end
    shared :b do |n1, s1, s2, s3, n2|
      c "#{s3}#{s1}#{n2}#{s2}#{n1}"
    end
    type :test do
      attr :c
    end
    1.upto(10) do |n|
      test "t#{n}" do
        include :a, 'd'
        c.must_equal('d')
        include :b, n, 'a', 'b', 'c', 4
        c.must_equal("ca4b#{n}")
      end
    end
  end
end

jtest 'catches argument mismatches' do
  assert_jaba_error "Error at #{src_loc('948EFABB')}: Shared definition ':d' expects 3 arguments but 0 were passed." do
    jaba(barebones: true) do
      shared :d do |a1, a2, a3|
      end
      type :t
      t :a do
        include :d # 948EFABB
      end
    end
  end
  assert_jaba_error "Error at #{src_loc('DCABE68F')}: Shared definition ':e' expects 0 arguments but 1 were passed." do
    jaba(barebones: true) do
      shared :e do
      end
      type :t
      t :a do
        include :e, 1 # DCABE68F
      end
    end
  end
  assert_jaba_error "Error at #{src_loc('35DEF7A9')}: Shared definition ':f' expects 2 arguments but 3 were passed." do
    jaba(barebones: true) do
      shared :f do |a1, a2|
      end
      type :t
      t :a do
        include :f, 1, 2, 3 # 35DEF7A9
      end
    end
  end
end

jtest 'can chain includes' do
end
