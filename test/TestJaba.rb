require 'minitest/spec'
require_relative '../lib/jaba/jaba'

module JABA

  class JabaTest < Minitest::Spec
    
    ##
    #
    def jaba(load_paths: nil, &block)
      JABA.run do |c|
        c.load_paths = load_paths
        c.definitions(&block) if block_given?
      end
    end
    
    ##
    #
    def temp_dir
    # TODO: ensure dir exists
      "#{__dir__}/tests/temp"
    end
    
    ##
    # Helper for testing error reporting.
    #
    def find_line_number(string, file)
      IO.read(file).each_line.find_index {|line| line.include?(string)} + 1
    end
  
  end
  
end

Dir.glob("#{__dir__}/tests/*.rb").each{|f| require f}

Minitest.run(ARGV)
