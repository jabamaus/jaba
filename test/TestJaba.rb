require'minitest/spec'


module JABA

  class JabaTestCase < Minitest::Spec
    
    def jaba(&block)
      Jaba.run do |c|
        if block_given?
          c.definitions do
            instance_eval(&block)
          end
        end
      end
    end
    
  end
  
  class TestJaba < JabaTestCase

    describe 'Jaba' do
      
    end

  end
  
end

Minitest.run(ARGV)
