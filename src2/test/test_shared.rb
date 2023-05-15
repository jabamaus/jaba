jtest "disallows include at top level" do
  jaba do
    JTest.assert_jaba_error(/Error at #{JTest.src_loc("3001F43A")}: 'include' attr\/method not defined/) do
      include :a # 3001F43A
    end
  end
end

jtest "fails if shared definition does not exist" do
  jdl do
    node :node
  end
  jaba do
    shared :a do
    end
    node :n do
      JTest.assert_jaba_error "Error at #{JTest.src_loc("6E431814")}: shared definition ':b' not defined." do
        include :b # 6E431814
      end
    end
  end
end

jtest "fails if shared definition multiply defined" do
  jaba do
    shared :a do
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("8EE6FCB3")}: shared definition ':a' multiply defined." do
      shared :a do # 8EE6FCB3
      end
    end
  end
end

jtest "includes things" do
  jdl do
    node :node
    attr "node/a"
  end
  jaba do
    shared :a do
      a 1
    end
    shared :b do
      include :a
    end
    node :n do
      include :b
      a.must_equal 1
    end
  end
end

jtest "supports passing keyword args to shared definitions" do
  jdl do
    node :node
    attr "node/c"
  end
  jaba do
    shared :a do |arg1:, arg2: nil, arg3: "f"|
      c "#{arg1}#{arg2}#{arg3}"
    end
    node :n do
      include :a, arg1: "d", arg3: "e"
      c.must_equal "de"
    end
  end
end
