require_relative "../jaba"

JABA.running_tests!

module JabaTestMethods
  def jdl(&block)
    JABA.set_test_api_block(&block)
  end

  def jaba(
    want_exceptions: true,
    src_root: nil,
    global_attrs_from_cmdline: nil,
    &block
  )
    if (src_root && block) || (!src_root && !block)
      raise "src_root or block must be provided but not both"
    end

    JABA.run do |c|
      c.want_exceptions = want_exceptions
      if src_root
        c.src_root = src_root
      else
        c.definitions(&block)
      end
      c.global_attrs_from_cmdline = global_attrs_from_cmdline
    end
  end

  def jtest_post_test
    JABA.restore_core_api
  end

  def assert_jaba_error(msg, hint: nil, &block)
    src_loc = calling_location
    e = assert_raises(JABA::JabaError, src_loc: src_loc, msg: hint) do
      yield
    end

    if msg.is_a?(Regexp)
      e.message.must_match(msg, src_loc: src_loc)
    else
      e.message.must_equal(msg, src_loc: src_loc)
    end
    e
  end

  def assert_jaba_file_error(msg, tag, &block)
    src_loc_ = calling_location
    fn = "#{temp_dir}/test.jaba"
    str = block.call
    make_file(fn, content: str)
    op = jaba(src_root: fn, want_exceptions: false)
    if msg.is_a?(Regexp)
      op[:error].must_match(/Error at #{src_loc(tag, file: fn)}: #{msg}/, src_loc: src_loc_)
    else
      op[:error].must_equal("Error at #{src_loc(tag, file: fn)}: #{msg}", src_loc: src_loc_)
    end
  end
end

class JTestCaseAPI; include JabaTestMethods; end

JTest.extend(JabaTestMethods)
