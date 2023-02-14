jtest 'defaults to false' do
  jaba do
    test :t do
      a.must_equal(false)
    end
  end
end