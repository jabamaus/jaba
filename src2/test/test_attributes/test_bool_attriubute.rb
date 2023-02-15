jtest 'defaults to false' do
  jaba do
    test :t do
      bool_attr.must_equal(false)
    end
  end
end