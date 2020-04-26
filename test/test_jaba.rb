# frozen_string_literal: true

require 'minitest'
require 'minitest/spec'
require_relative '../lib/jaba/jaba'

module JABA
  using JABACoreExt

  ATTR_DEFINITION_FILE = "#{__dir__}/../lib/jaba/definitions/attribute_types.rb".cleanpath
  TEXT_DEFINITION_FILE = "#{__dir__}/../lib/jaba/definitions/text.rb".cleanpath
  CPP_DEFINITION_FILE = "#{__dir__}/../lib/jaba/definitions/cpp.rb".cleanpath

  class JabaTest < Minitest::Spec
    
    @@file_cache = {}

    ##
    #
    def jaba(load_paths: nil, &block)
      op = JABA.run do |c|
        c.load_paths = load_paths
        c.definitions(&block) if block_given?
        c.dump_output = false
        c.use_file_cache = true
        c.use_glob_cache = true
      end
      warnings = op[:warnings]
      puts warnings if warnings
      op
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
    def find_line_number(file, spec)
      return spec if spec.is_a?(Numeric)
      ln = if spec.start_with?('tag')
        $tag_to_line["#{file}##{spec}"]
      else
        str = @@file_cache[file]
        if str.nil?
          str = IO.read(file)
          @@file_cache[file] = str
        end
        str.each_line.find_index {|l| l =~ / #{Regexp.escape(spec)}/}
      end
      raise "#{spec} not found" if ln.nil?
      ln + 1
    end

    ##
    #
    def check_fail(msg, trace:)
      e = assert_raises JabaError do
        yield
      end
      
      file = trace[0]
      line = find_line_number(file, trace[1])
      
      e.message.must_match(msg)
      e.file.must_equal(file)
      e.line.must_equal(line)
      
      backtrace = []
      trace.each_slice(2) do |elem|
        backtrace << "#{elem[0]}:#{find_line_number(elem[0], elem[1])}"
      end
      e.backtrace.slice(0, backtrace.size).must_equal(backtrace)
      e
    end
    
    ##
    #
    def check_warn(msg, expected_file, tag)
      out, _ = capture_io do
        yield
      end
      
      out.must_match(msg)
      expected_line = find_line_number(expected_file, tag)

      if out !~ /Warning at (.+):(\d+)/
        raise "couldn't extract file and line number from warning"
      end
      
      actual_file = Regexp.last_match(1)
      actual_line = Regexp.last_match(2).to_i

      actual_file.must_equal(expected_file.basename)
      actual_line.must_equal(expected_line)
    end

  end

  if File.exist?(JabaTest.temp_root)
    FileUtils.remove_dir(JabaTest.temp_root)
  end
  
end

$tag_to_line = {}

# Load each test file as a string, extract all the '# tag' lines and execute the file.
#
Dir.glob("#{__dir__}/tests/*.rb").sort.each do |f|
  str = IO.read(f)
  index = 0
  str.each_line(chomp: true) do |ln|
    if ln =~ / # (tag.)/
      tag_id = "#{f}##{Regexp.last_match(1)}"
      $tag_to_line[tag_id] = index
    end
    index += 1
  end
  eval(str, nil, f)
end

using JABACoreExt

profile(enabled: ARGV.delete('--profile')) do
  Minitest.run(ARGV)
end
