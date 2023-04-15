jtest "warns if path not clean" do
  JDL.node "node_83D99E1E"
  JDL.attr "node_83D99E1E|file", type: :file
  JDL.attr "node_83D99E1E|dir", type: :dir
  JDL.attr "node_83D99E1E|src_spec", type: :src_spec
  assert_jaba_warn "'file' attribute not specified cleanly: 'a\\b' contains backslashes", __FILE__, "4E60BC17" do
    jaba do
      node_83D99E1E :t do
        file "a\\b" # 4E60BC17
      end
    end
  end
  assert_jaba_warn "'dir' attribute not specified cleanly: 'a\\b' contains backslashes", __FILE__, "F7B16193" do
    jaba do
      node_83D99E1E :t do
        dir "a\\b" # F7B16193
      end
    end
  end
  assert_jaba_warn "'src_spec' attribute not specified cleanly: 'a\\b' contains backslashes", __FILE__, "CE17A7F3" do
    jaba do
      node_83D99E1E :t do
        src_spec "a\\b" # CE17A7F3
      end
    end
  end
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
