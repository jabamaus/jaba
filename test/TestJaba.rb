require 'minitest/spec'
require_relative '../lib/jaba/jaba'

module JABA
  
CoreTypesFile = "C:/projects/GitHub/jaba/lib/jaba/core/Types.rb" # TODO: remove hard coded absolute path

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
  def self.temp_root
    "#{__dir__}/tests/temp"
  end
  
  ##
  #
  def temp_dir
    dir = "#{JabaTest.temp_root}/#{self.class.name.split('::').last}/#{self.name.delete(':')}"
    if !File.exist?(dir)
      FileUtils.makedirs(dir)
    end
    dir
  end
  
  ##
  # Helper for testing error reporting.
  #
  def find_line_number(file, line)
    return line if line.is_a?(Numeric)
    if !File.exist?(file)
      raise "#{file} does not exist"
    end
    ln = IO.read(file).each_line.find_index {|l| l =~ /^\s+#{Regexp.escape(line)}/}
    if ln.nil?
      raise "'#{line}' not found in #{file}"
    end
    ln + 1
  end

  ##
  #
  def check_fails(msg, backtrace:, internal: false)
    e = assert_raises JabaError do
      yield
    end
    
    file = backtrace[0][0]
    line = find_line_number(file, backtrace[0][1])
    
    e.file.must_equal(file)
    e.line.must_equal(line)
    e.message.must_match(msg)
    e.internal?.must_equal(internal)
    
    backtrace = backtrace.map{|elem| "#{elem[0]}:#{find_line_number(elem[0], elem[1])}"}
    e.backtrace.slice(0, backtrace.size).must_equal(backtrace)
    e
  end
end

if File.exist?(JabaTest.temp_root)
  FileUtils.remove_dir(JabaTest.temp_root)
end
  
end

Dir.glob("#{__dir__}/tests/*.rb").each{|f| require f}

Minitest.run(ARGV)
