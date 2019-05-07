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
    dir = "#{JabaTest.temp_root}/#{self.name.delete(':')}"
    if !File.exist?(dir)
      FileUtils.makedirs(dir)
    end
    dir
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

if File.exist?(JabaTest.temp_root)
  FileUtils.remove_dir(JabaTest.temp_root)
end
  
end

Dir.glob("#{__dir__}/tests/*.rb").each{|f| require f}

Minitest.run(ARGV)
