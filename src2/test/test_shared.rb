jtest "includes jaba file when called at file scope" do
  make_file("a.jaba", content: "a 1\ninclude \"b\"")
  # include sub1 directory containing jaba files (not recursive) and sub2 recursively
  make_file("b.jaba", content: "b 2\ninclude \"sub1\"\ninclude \"sub3/**/*\"")
  make_file("sub1/c.jaba", content: "c 3")
  make_file("sub1/d.jaba", content: "d 4")
  make_file("sub1/file.dummy", content: "will not be included")
  make_file("sub1/sub2/file.dummy", content: "will not be included")
  make_file("sub3/e.jaba", content: "e 5")
  make_file("sub3/f.jaba", content: "f 6")
  make_file("sub3/sub4/g.jaba", content: "g 7")
  make_file("sub3/sub4/file.dummy", content: "will not be included")

  td = temp_dir
  dir = __dir__

  jdl do
    attr :a, type: :int
    attr :b, type: :int
    attr :c, type: :int
    attr :d, type: :int
    attr :e, type: :int
    attr :f, type: :int
    attr :g, type: :int
  end
  jaba do
    include "#{td}/a"
    a.must_equal 1
    b.must_equal 2
    c.must_equal 3
    d.must_equal 4
    e.must_equal 5
    f.must_equal 6
    g.must_equal 7
    JTest.assert_jaba_error "Error at #{JTest.src_loc("28577C16")}: '#{td}/unknown1.jaba' does not exist." do
      include "#{td}/unknown1" # 28577C16
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("A8B36167")}: '#{dir}/unknown2.jaba' does not exist." do
      include "unknown2" # A8B36167
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
