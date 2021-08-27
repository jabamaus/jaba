# frozen_string_literal: true

require_relative '../lib/jaba'
require 'minitest'
require 'minitest/spec'

# Disallow describe statements. They don't play well with automatic per-test temp dirs
module Kernel
  remove_method :describe

  def describe(...)
    raise 'describe statements cannot be used in jaba tests'
  end
end

module JABA

  using JABACoreExt

  ##
  #
  def self.run_tests
    Dir.glob("#{__dir__}/tests/**/*.rb").each {|f| require f}
    if File.exist?(JabaTest.temp_root)
      FileUtils.remove_dir(JabaTest.temp_root)
    end
    @@running_tests = true
    args_index = ARGV.index('--')
    argv = args_index.nil? ? [] : ARGV[args_index+1..-1]
    ::Minitest.run(argv + ["--no-plugins"])
  end

  class JabaTest < Minitest::Spec
    
    @@file_cache = {}

    ##
    #
    def jaba(barebones: false,
             want_exceptions: true,
             src_root: nil,
             build_root: nil,
             argv: nil,
             dry_run: false,
             dump_output: false,
             cpp_app: false,
             cpp_defaults: false, &block)
      td = temp_dir(create: false)
      build_root = build_root || td
      op = JABA.run(want_exceptions: want_exceptions) do |c|
        c.src_root = src_root # Most unit tests don't have a src_root as everything is defined inline in code
        c.build_root = build_root
        c.argv = Array(argv) if argv
        c.definitions(&block) if block_given?
        c.barebones = barebones
        if cpp_app || cpp_defaults
          c.definitions do
            defaults :cpp do
              platforms [:windows_x86, :windows_x86_64]
              configs [:Debug, :Release]
              root td
              type :app if cpp_app
            end
          end
        end
        c.definitions do
          open_instance :globals, type: :globals do
            target_hosts :vs2019
            dump_output dump_output
            jaba_output_file "#{build_root}/jaba.output.json"
          end
        end
        c.dry_run = dry_run
      end
      warnings = op[:warnings]
      puts warnings if warnings
      if cpp_app
        op = op[:cpp]['app|vs2019|windows']
        op.wont_be_nil
      end
      op
    end

    ##
    #
    def self.temp_root
      "#{__dir__}/tests/temp"
    end
    
    ##
    #
    def temp_dir(create: true)
      dir = "#{JabaTest.temp_root}/#{self.class.name_no_namespace}/#{name.delete(':')}"
      if create && !File.exist?(dir)
        FileUtils.makedirs(dir)
      end
      dir
    end
    
    ##
    #
    def make_dir(*dirs)
      dirs.each do |dir|
        d = dir.absolute_path? ? dir : "#{temp_dir}/#{dir}"
        if !File.exist?(d)
          FileUtils.makedirs(d)
        end
      end
    end

    ##
    #
    def make_file(*fns, content: "test\n")
      fns.each do |fn|
        fn = "#{temp_dir}/#{fn}"
        make_dir(fn.dirname)
        IO.write(fn, content)
      end
    end
    
    ##
    #
    def src_loc(file, tag)
      "#{file.basename}:#{find_line_number(file, tag)}"
    end

    ##
    # Helper for testing error reporting.
    #
    def find_line_number(file, spec)
      return spec if spec.is_a?(Numeric)
      str = @@file_cache[file]
      if str.nil?
        str = IO.read(file)
        @@file_cache[file] = str
      end
      ln = str.each_line.find_index {|l| l =~ / #{Regexp.escape(spec)}/}
      raise "\"#{spec}\" not found in #{file}" if ln.nil?
      ln + 1
    end

    ##
    #
    def check_fail(msg, line: nil, trace: nil)
      e = assert_raises JabaError do
        yield
      end
      
      e.message.must_match(msg)

      if line
        file = line[0]
        line = find_line_number(file, line[1])
        
        e.file.must_equal(file)
        e.line.must_equal(line)
      end

      if trace
        backtrace = []
        trace.each_slice(2) do |elem|
          backtrace << "#{elem[0]}:#{find_line_number(elem[0], elem[1])}"
        end
        e.backtrace.slice(1, backtrace.size).must_equal(backtrace, 'backtrace did not match')
      end
      e
    end
    
    ##
    #
    def assert_jaba_error(msg, trace: [])
      e = assert_raises JabaError do
        yield
      end
      
      e.message.must_equal(msg)

      if trace
        backtrace = []
        trace.each_slice(2) do |elem|
          backtrace << "#{elem[0]}:#{find_line_number(elem[0], elem[1])}"
        end

        # First backtrace item contains the same file and line number as the main message line so disregard
        #
        bt = e.backtrace
        bt.shift
        bt.must_equal(backtrace, 'backtrace did not match')
      end
      e
    end

    ##
    #
    def check_warn(msg, expected_file = nil, tag = nil)
      out, = capture_io do
        yield
      end
      
      out.must_match(msg)
      
      if expected_file
        expected_line = find_line_number(expected_file, tag)

        if out !~ /Warning at (.+?):(\d+)/
          raise "couldn't extract file and line number from warning"
        end
        
        actual_file = Regexp.last_match(1)
        actual_line = Regexp.last_match(2).to_i

        actual_file.must_equal(expected_file.basename)
        actual_line.must_equal(expected_line)
      end
    end

  end
  
end

JABA.run_tests