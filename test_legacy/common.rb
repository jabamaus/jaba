require_relative '../src/jaba'

class JTestCaseAPI
  
  def jaba(barebones: false,
           test_mode: true,
           want_exceptions: true,
           src_root: nil,
           build_root: nil,
           dry_run: false,
           dump_output: false,
           cpp_app: false,
           cpp_defaults: false,
           global_attrs: {},
           &block)
    td = temp_dir(create: false)
    build_root = build_root || td

    op = JABA.run(want_exceptions: want_exceptions, test_mode: test_mode) do |c|
      c.src_root = src_root # Most unit tests don't have a src_root as everything is defined inline in code
      c.build_root = build_root
      c.definitions(&block) if block_given?
      c.barebones = barebones
      c.dump_output = dump_output
      c.dry_run = dry_run
      
      c.global_attrs = global_attrs
      if (!c.global_attrs.has_key?('target_host') && !c.global_attrs.has_key?(:target_host))
        c.global_attrs[:target_host] = :vs2019
      end

      if cpp_app || cpp_defaults
        c.definitions do
          defaults :cpp do
            platforms [:windows_x86, :windows_x86_64]
            root td
            project do
              configs [:Debug, :Release]
              type :app if cpp_app
            end
          end
        end
      end
    end

    warnings = op[:warnings]
    puts warnings if warnings
    
    if cpp_app
      op = op[:cpp]['app|windows']
      op.wont_be_nil
    end
    op
  end

  def assert_jaba_error(msg, trace: [], ignore_rest: false, hint: nil, &block)
    e = assert_raises(JABA::JabaError, msg: hint) do
      yield
    end

    if ignore_rest
      e.message.slice(0, msg.length).must_equal(msg)
    else
      e.message.must_equal(msg)
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
      bt.delete_if{|l| l =~ /cpp_plugin\.jaba|workspace_plugin\.jaba/}
      bt.must_equal(backtrace, msg: 'backtrace did not match')
    end
    e
  end

  def assert_jaba_warn(msg, expected_file = nil, tag = nil)
    out, = capture_io do
      yield
    end
    
    out.must_match(msg)
    
    if expected_file
      expected_line = src_line(tag, file: expected_file)

      if out !~ /Warning at (.+?):(\d+)/
        raise "couldn't extract file and line number from #{out}"
      end
      
      actual_file = Regexp.last_match(1)
      actual_line = Regexp.last_match(2).to_i

      actual_file.must_equal(expected_file.basename)
      actual_line.must_equal(expected_line)
    end
  end

end
