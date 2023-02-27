require_relative "../jaba"

JABA.running_tests!

JDL.node "test"

class JTestCaseAPI
  def jaba(want_exceptions: true, src_root: nil, build_root: nil, global_attrs: nil, &block)
    td = temp_dir(create: false)
    build_root = build_root || td

    op = JABA.run(want_exceptions: want_exceptions) do |c|
      c.src_root = src_root # Most unit tests don't have a src_root as everything is defined inline in code
      c.build_root = build_root
      c.definitions(&block) if block_given?
      c.global_attrs = global_attrs
    end

    warnings = op[:warnings]
    puts warnings if warnings
    op
  end

  def assert_jaba_error(msg, trace: nil, ignore_rest: false, hint: nil, &block)
    src_loc = calling_location
    e = assert_raises(JABA::JabaError, src_loc: src_loc, msg: hint) do
      yield
    end

    if ignore_rest
      e.message.slice(0, msg.length).must_equal(msg, src_loc: src_loc)
    else
      e.message.must_equal(msg, src_loc: src_loc)
    end

    if trace
      backtrace = []
      trace.each_slice(2) do |elem|
        backtrace << "#{elem[0]}:#{src_line(elem[1], file: elem[0])}"
      end

      # First backtrace item contains the same file and line number as the main message line so disregard
      #
      bt = e.backtrace
      bt.shift
      bt.must_equal(backtrace, msg: "backtrace did not match", src_loc: src_loc)
    end
    e
  end

  def assert_jaba_file_error(msg, tag, &block)
    src_loc_ = calling_location
    fn = "#{temp_dir}/test.jaba"
    str = block.call
    make_file(fn, content: str)
    op = jaba(src_root: fn, want_exceptions: false)
    op[:error].must_equal("Error at #{src_loc(tag, file: fn)}: #{msg}", src_loc: src_loc_)
  end

  def assert_jaba_warn(msg, expected_file = nil, tag = nil)
    src_loc = calling_location
    out, = capture_io do
      yield
    end

    out.must_match(msg, src_loc: src_loc)

    if expected_file
      expected_line = src_line(tag, file: expected_file)

      if out !~ /Warning at (.+?):(\d+)/
        raise "couldn't extract file and line number from #{out}"
      end

      actual_file = Regexp.last_match(1)
      actual_line = Regexp.last_match(2).to_i

      actual_file.must_equal(expected_file.basename, src_loc: src_loc)
      actual_line.must_equal(expected_line, src_loc: src_loc)
    end
  end
end
