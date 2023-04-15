jtest "warns if path not clean" do
  JDL.node "node_83D99E1E"
  JDL.attr "node_83D99E1E|file", type: :file
  JDL.attr "node_83D99E1E|dir", type: :dir
  JDL.attr "node_83D99E1E|src_spec", type: :src_spec
  op = jaba do
    node_83D99E1E :t do
      file "a\\b" # 4E60BC17
      dir "a\\b" # F7B16193
      src_spec "a\\b" # CE17A7F3
    end
  end
  w = op[:warnings]
  w.size.must_equal 3
  w[0].must_equal "Warning at #{src_loc("4E60BC17")}: 'file' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[1].must_equal "Warning at #{src_loc("F7B16193")}: 'dir' attribute not specified cleanly: 'a\\b' contains backslashes."
  w[2].must_equal "Warning at #{src_loc("CE17A7F3")}: 'src_spec' attribute not specified cleanly: 'a\\b' contains backslashes."
end

# TODO: test paths starting with ./
=begin
jtest "rejects slashes in basename" do
  ['a\b', "a/b"].each do |val|
    assert_jaba_error "Error at #{src_loc("D8744964")}: 't.a' attribute invalid: '#{val}' must not contain slashes." do
      jaba(barebones: true) do
        type :test do
          attr :a, type: :basename
        end
        test :t do
          a val # D8744964
        end
      end
    end
  end
end
=end
