# frozen_string_literal: true

require 'minitest'
require 'minitest/spec'
require_relative '../lib/jaba/jaba'

module JABA
  using JABACoreExt

  ATTR_TYPES_FILE = "#{__dir__}/../lib/jaba/definitions/attribute_types.rb".cleanpath
  TEXT_TYPES_FILE = "#{__dir__}/../lib/jaba/definitions/text.rb".cleanpath

  class JabaTest < Minitest::Spec
    
    ##
    #
    def jaba(load_paths: nil, &block)
      JABA.run do |c|
        c.load_paths = load_paths
        c.definitions(&block) if block_given?
        c.dump_output = false
        c.use_file_cache = true
        c.use_glob_cache = true
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
      dir = "#{JabaTest.temp_root}/#{self.class.name_no_namespace}/#{name.delete(':')}"
      if !File.exist?(dir)
        FileUtils.makedirs(dir)
      end
      dir
    end
    
    ##
    #
    def make_file(f)
      IO.write("#{temp_dir}/#{f}", "test\n")
    end
    
    ##
    # Helper for testing error reporting.
    #
    def find_line_number(file, line)
      return line if line.is_a?(Numeric)
      if !File.exist?(file)
        raise "#{file} does not exist"
      end
      ln = IO.read(file).each_line.find_index {|l| l =~ / #{Regexp.escape(line)}/}
      if ln.nil?
        raise "'#{line}' not found in #{file}"
      end
      ln + 1
    end

    ##
    #
    def check_fail(msg, trace:, internal: false)
      e = assert_raises JabaError do
        yield
      end
      
      file = trace[0]
      line = find_line_number(file, trace[1])
      
      e.message.must_match(msg)
      e.file.must_equal(file)
      e.line.must_equal(line)
      e.internal.must_equal(internal)
      
      backtrace = []
      trace.each_slice(2) do |elem|
        backtrace << "#{elem[0]}:#{find_line_number(elem[0], elem[1])}"
      end
      e.backtrace.slice(0, backtrace.size).must_equal(backtrace)
      e
    end
    
  end

  if File.exist?(JabaTest.temp_root)
    FileUtils.remove_dir(JabaTest.temp_root)
  end
  
end

Dir.glob("#{__dir__}/tests/*.rb").sort.each {|f| require f}

using JABACoreExt

profile(enabled: ARGV.delete('--profile')) do
  Minitest.run(ARGV)
end
