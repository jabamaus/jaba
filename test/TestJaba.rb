require'minitest/spec'


module JABA

  class JabaTestCase < Minitest::Spec
  end
  
  class TestJaba < JabaTestCase

    describe 'Jaba' do
    end

  end
  
end

Minitest.run(ARGV)
