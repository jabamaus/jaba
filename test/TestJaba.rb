require 'minitest/spec'
require_relative '../lib/jaba/jaba'

module JABA

  class JabaTestCase < Minitest::Spec
    
    def jaba(&block)
      JABA.run do |c|
        if block_given?
          c.definitions do
            instance_eval(&block)
          end
        end
      end
    end
    
  end
  
end

Dir.glob("#{__dir__}/tests/*.rb").each{|f| require f}

Minitest.run(ARGV)
