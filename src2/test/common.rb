require_relative '../jaba'

JABA.running_tests!

JDL.node 'test'
JDL.attr 'test|bool_attr', type: :bool do
  title 'bool_attr'
end

class JTestCaseAPI
  def jaba(want_exceptions: true, src_root: nil, build_root: nil, &block)
    td = temp_dir(create: false)
    build_root = build_root || td

    op = JABA.run(want_exceptions: want_exceptions) do |c|
      c.src_root = src_root # Most unit tests don't have a src_root as everything is defined inline in code
      c.build_root = build_root
      c.definitions(&block) if block_given?
    end

    warnings = op[:warnings]
    puts warnings if warnings
    op
  end
end
