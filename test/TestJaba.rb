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
      if !File.exist?(file)
        raise "#{file} does not exist"
      end
      ln = IO.read(file).each_line.find_index {|l| l =~ /^\s+#{Regexp.escape(string)}/}
      if ln.nil?
        raise "'#{string}' not found in #{file}"
      end
      ln + 1
    end
  
    ##
    #
    def check_fails(msg:, file:, line:, backtrace: nil)
      e = assert_raises DefinitionError do
        yield
      end
      e.message.must_match(msg)
      e.file.must_equal(file)
      e.line.must_equal(find_line_number(line, file))
      if backtrace
        e.backtrace.must_equal(backtrace)
      else
        e.backtrace.must_equal([])
      end
      e
    end
  end
  
end

Dir.glob("#{__dir__}/tests/*.rb").each{|f| require f}

Minitest.run(ARGV)
