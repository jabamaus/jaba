# In this file 'jdl' errors refer to violations of the jaba definition language that are not deeper ruby errors (eg syntax)
# Also backtraces in inline block form are different to normal file usage so they are ignored here

jtest "catches jdl errors in block form" do
  assert_jaba_error "Error at #{src_loc("49EBF5E4")}: 'invalid id' is an invalid id. Must be an " \
                    "alphanumeric string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'." do
    jaba do
      target "invalid id" # 49EBF5E4
    end
  end
end

jtest "catches jdl errors in jaba file form" do
  assert_jaba_file_error "'invalid id' is an invalid id. Must be an alphanumeric " \
                         "string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'.", "32C24F15" do
    "target \"invalid id\" # 32C24F15"
  end
end

jtest "catches constant errors in block form" do
  assert_jaba_error(/Error at #{src_loc("138FA33C")}: uninitialized constant BADCODE/) do
    jaba do
      BADCODE # 138FA33C
    end
  end
end

jtest "catches constant errors in jaba file form" do
  assert_jaba_file_error(/uninitialized constant #<Class:.+>::BADCODE\./, 1) do
    "BADCODE"
  end
end

jtest "catches syntax errors in jaba file form" do
  fullpath = "#{temp_dir}/test.jaba"
  IO.write(fullpath, "\n\n&*^^\n")
  assert_jaba_error "Syntax error at test.jaba:3: unexpected &" do
    jaba(src_root: fullpath)
  end
end

jtest "reports lines correctly when using shared modules" do
  assert_jaba_error "Error at #{src_loc("7F3590D4")}: 'a' attribute invalid - 'invalid' is a string - expected [true|false]" do
    jdl do
      node :node
      attr "node/a", type: :bool
    end
    jaba do
      shared :s do
        a "invalid" # 7F3590D4
      end
      node :n do
        include :s
      end
    end
  end
end

jtest "allows errors to be raised from definitions in block form" do
  assert_jaba_error "Error at #{src_loc("7FAC4085")}: Error msg." do
    jaba do
      fail "Error msg" # 7FAC4085
    end
  end
end

jtest "allows errors to be raised from definitions in jaba file form" do
  assert_jaba_file_error "Error msg.", "D3BBCE42" do
    "fail \"Error msg\" # D3BBCE42"
  end
end

jtest "supports core errors" do
  op = JABA.run do |c|
    c.want_exceptions = false
    JABA.error("an error occurred", want_backtrace: false) # 6DF68D4B
  end
  op[:error].must_equal "Error at #{src_loc("6DF68D4B")}: an error occurred."

  op = JABA.run do |c|
    c.want_exceptions = false
    JABA.error("an error occurred", want_backtrace: true) # 23D59345
  end
  op[:error].must_match "Error at #{src_loc("23D59345")}: an error occurred.\nTrace:"

  e = assert_raises JABA::JabaError do
    JABA.run do |c|
      c.want_exceptions = true
      JABA.error("an error occurred", want_backtrace: true) # 2252C945
    end
  end
  e.message.must_equal("Error at #{src_loc("2252C945")}: an error occurred.")
  e.backtrace.empty?.must_be_false

  e = assert_raises JABA::JabaError do
    JABA.run do |c|
      c.want_exceptions = true
      JABA.error("an error occurred", want_backtrace: false) # D0E1DE85
    end
  end
  e.message.must_equal("Error at #{src_loc("D0E1DE85")}: an error occurred.")

  # there is still a backtrace even though want_backtrace is false because want_backtrace
  # only affects jaba's return error not the exception.
  #
  e.backtrace.empty?.must_be_false
end
