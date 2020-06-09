# frozen_string_literal: true

require 'minitest'
require 'minitest/spec'

module JABA

  using JABACoreExt

  ##
  #
  def self.run_tests
    @@running_tests = true
    ::Minitest.run(ARGV)
  end

  ##
  def self.init_tests
    if File.exist?(JabaTest.temp_root)
      FileUtils.remove_dir(JabaTest.temp_root)
    end
  end

  ATTR_TYPES_FILE = "#{__dir__}/../lib/jaba/definitions/attribute_types.rb".cleanpath

  class JabaTest < Minitest::Spec
    
    @@file_cache = {}

    ##
    #
    def jaba(barebones: false, load_paths: nil, dry_run: false, dump_output: false, cpp_app: false, cpp_defaults: false, &block)
      op = JABA.run do |c|
        c.load_paths = load_paths
        c.definitions(&block) if block_given?
        c.barebones = barebones
        td = temp_dir
        c.jaba_output_file = "#{td}/jaba.output.json"
        if cpp_app || cpp_defaults
          # force dump output to ensure that output paths are made relative to the temp_dir and therefore the
          # root, for easy testing. If the output is not written to disk the paths are left as absolute.
          dump_output = true
          c.definitions do
            defaults :cpp do
              hosts [:vs2019]
              platforms [:windows]
              archs [:x86, :x86_64]
              configs [:Debug, :Release]
              root td
              type :app if cpp_app
            end
          end
        end
        c.dump_output = dump_output
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
    def temp_dir
      dir = "#{JabaTest.temp_root}/#{self.class.name_no_namespace}/#{name.delete(':')}"
      if !File.exist?(dir)
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
    def make_file(*fns)
      fns.each do |fn|
        fn = "#{temp_dir}/#{fn}"
        make_dir(fn.dirname)
        IO.write(fn, "test\n")
      end
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
      raise "\"#{spec}\" not found in #{file}" if ln.nil?
      ln + 1
    end

    ##
    #
    def check_fail(msg, exception: JabaDefinitionError, trace: nil)
      e = assert_raises exception do
        yield
      end
      
      e.message.must_match(msg)

      if trace
        file = trace[0]
        line = find_line_number(file, trace[1])
        
        e.file.must_equal(file)
        e.line.must_equal(line)
        
        backtrace = []
        trace.each_slice(2) do |elem|
          backtrace << "#{elem[0]}:#{find_line_number(elem[0], elem[1])}"
        end
        e.backtrace.slice(0, backtrace.size).must_equal(backtrace)
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
