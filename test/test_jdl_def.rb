jtest "split_jdl_path" do
  b = JABA::JDLBuilder.new([])
  parent, elem = b.send(:split_jdl_path, "a/b/c")
  parent.must_equal "a/b"
  elem.must_equal "c"
  b.send(:split_jdl_path, "a/b").must_equal ["a", "b"]
  b.send(:split_jdl_path, "*/b").must_equal ["*", "b"]
  b.send(:split_jdl_path, "a").must_equal [nil, "a"]
end

jtest "validates jdl path format" do
  jdl do
    node :n
    JTest.assert_jaba_error "Error at #{JTest.src_loc("5CFB9574")}: 'n|a' is in invalid format." do
      attr "n|a" # 5CFB9574 pipes not allowed
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("9B9B965C")}: 'n/a__b' is in invalid format." do
      attr "n/a__b" # 9B9B965C only 1 underscore allowed
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("C42FF3D2")}: 'n/a b' is in invalid format." do
      attr "n/a b" # C42FF3D2 spaces not allowed
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("B90811C7")}: 'n//a_b' is in invalid format." do
      attr "n//a_b" # B90811C7 double slashes not allowed
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("D54FA196")}: 'n/a_b/' is in invalid format." do
      attr "n/a_b/" # D54FA196 cannot end in slash
    end
  end
  jaba do end
end

jtest "checks parent path valid" do
  jdl do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("24DB3815")}: No 'a' node registered." do
      attr "a/b" # 24DB3815
    end
  end
  jaba do end
end

jtest "checks for duplicate paths" do
  jdl do
    node "n"
    JTest.assert_jaba_error "Error at #{JTest.src_loc("99E1CB75")}: Duplicate 'n' node registered." do
      node "n" # 99E1CB75
    end
    attr "n/a"
    JTest.assert_jaba_error "Error at #{JTest.src_loc("BC9DD62C")}: Duplicate 'n/a' attribute registered." do
      attr "n/a" # BC9DD62C
    end
    method "n/m" do
      on_called do end
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("87285F34")}: Duplicate 'n/m' method registered." do
      method "n/m" # 87285F34
    end
  end
  jaba do end
end

jtest "can register methods at top level" do
  jdl(level: :core) do
    method :m do
      on_called do Kernel.print "m" end
    end
    node :node
  end
  jaba do
    available.include?("m").must_be_true
    JTest.assert_output "m" do
      m
    end
    node :n do
      JTest.assert_jaba_error(/Error at #{JTest.src_loc("8140CFB7")}: 'm' attr\/method not defined/) do
        m # 8140CFB7
      end
    end
  end
end

jtest "can register methods into a specific node" do
  jdl do
    node :node
    method "node/m" do
      on_called do Kernel.print "m" end
    end
  end
  jaba do
    node :n do
      JTest.assert_output "m" do
        m
      end
    end
    JTest.assert_jaba_error(/Error at #{JTest.src_loc("527A4B81")}: 'm' attr\/method not defined/) do
      m # 527A4B81
    end
  end
end

jtest "can register methods into all nodes except top level" do
  jdl do
    node "node1"
    node "node2"
    method "*/m" do
      on_called do Kernel.print "m|" end
    end
  end
  assert_output "m|m|" do
    jaba do
      node1 :n1 do
        m
      end
      node2 :n2 do
        m
      end
    end
  end
  jaba do
    JTest.assert_jaba_error(/Error at #{JTest.src_loc("A62A894B")}: 'm' attr\/method not defined/) do
      m # A62A894B
    end
  end
end

jtest "can register methods globally" do
  jdl do
    node "node1"
    node "node2"
    global_method "m" do
      on_called do Kernel.print "m|" end
    end
  end
  assert_output "m|m|m|" do
    jaba do
      m
      node1 :n1 do
        m
      end
      node2 :n2 do
        m
      end
    end
  end
end

jtest "can register attributes into nodes" do
  jdl do
    node "node1"
    attr "node1/a"
    attr "*/b" # registers into all nodes, except top level
    node "node2"
  end
  jaba do
    JTest.assert_jaba_error(/Error at #{JTest.src_loc("2D0B33FE")}: 'b' attr\/method not defined/) do
      b 1 # 2D0B33FE
    end
    node1 :n1 do
      a 1
      b 2
    end
    node2 :n2 do
      b 2
    end
  end
end

jtest "can register attributes as node options" do
  jdl(level: :core) do
    attr "*/common_option" do
      flags :node_option
      default 3
    end
    attr "*/common_option_required" do
      flags :node_option, :required
    end
    node "node1"
    attr "node1/body_attr", type: :int
    attr "node1/a" do
      flags :node_option
    end
    node "node2"
    attr "node2/b" do
      flags :node_option, :required
    end
  end
  # non-option attrs cannot be passed in
  assert_jaba_error "Error at #{src_loc("A683789B")}: 'body_attr' attribute must be set in the definition body." do
    jaba do
      node1 :n, body_attr: 1 do # A683789B
      end
    end
  end
  jaba do
    node1 :n, a: 1, common_option: 2, common_option_required: 3 do
      a.must_equal 1
      common_option.must_equal 2
      common_option_required.must_equal 3
      JTest.assert_jaba_error "Error at #{JTest.src_loc("70E5EB5C")}: 'a' attribute is read only." do
        a 2 # 70E5EB5C
      end
    end
    node2 :n2, b: 1, common_option_required: 3 do
      b.must_equal 1
      common_option.must_equal 3 # default
      common_option_required.must_equal 3
    end
  end
  # Test works with :required flag
  # Wrap exception round whole jaba context as nodes are not processed immediately
  JTest.assert_jaba_error "Error at #{JTest.src_loc("AE7F70E6")}: 'node2' requires 'b' attribute to be passed in." do
    jaba do
      node2 :n2, common_option_required: 3 # AE7F70E6
    end
  end
  JTest.assert_jaba_error "Error at #{JTest.src_loc("4B0E0102")}: 'node2' requires 'common_option_required' attribute to be passed in." do
    jaba do
      node2 :n2, b: 1 # 4B0E0102
    end
  end
end

jtest "supports opening attribute definitions" do
  jdl do
    open_attr :a do
      items [:c]
      default :a # change default to :a
    end
    attr :a, type: :choice do
      items [:a, :b]
      default :b
    end
    open_attr :a do
      items [:d]
    end
  end
  jaba do
    a.must_equal :a
    a :c
    a.must_equal :c
    a :d
    a.must_equal :d
  end
end

# TODO: check for duplicate options
jtest "can register attributes as attribute options" do
  jdl(level: :core) do
    attr "a" do
      option :option, type: :choice do
        items [:a, :b, :c]
      end
    end
  end
  op = jaba do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("CD4DDB07")}: 'a' attribute requires 'option' option to be set." do
      a 1 # CD4DDB07
    end
    a 1, option: :b
  end
  a = op[:root].get_attr(:a)
  a.value.must_equal 1
  a.option_value(:option).must_equal :b
end

jtest "fails if attribute type does not exist" do
  assert_jaba_error(/Error at #{src_loc("CE16AD90")}: 'a' attribute invalid - ':unknown' must be one of \[:basename, .*\]/) do
    jdl do
      attr :a, type: :unknown # CE16AD90
    end
    jaba do end
  end
end

jtest "fails if flag does not exist" do
  assert_jaba_error(/Error at #{src_loc("01E55971")}: 'a' attribute invalid - ':unknown' must be one of \[:allow_dupes, .*\]/) do
    jdl do
      attr "a" do
        flags :unknown # 01E55971
      end
    end
    jaba do end
  end
end
