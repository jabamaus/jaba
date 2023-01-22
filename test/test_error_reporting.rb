jtest 'works when a definition contains an error when definitions in a block' do
  assert_jaba_error "Error at #{src_loc('49EBF5E4')}: 'invalid id' is an invalid id. Must be an " \
                  "alphanumeric string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'." do
    jaba do
      category 'invalid id' # 49EBF5E4
    end
  end
end

jtest 'works when a definition contains an error when definitions in separate file' do
  fullpath = "#{temp_dir}/test.jaba"
  IO.write(fullpath, "\n\ncategory 'invalid id' do\nend\n")
  line = 3
  assert_jaba_error "Error at test.jaba:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric " \
                  "string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'." do
    jaba(barebones: true, src_root: temp_dir)
  end
end

jtest 'works when there is a standard error when definitions in a block' do
  assert_jaba_error "Error at #{src_loc('138FA33C')}: uninitialized constant TestErrorReporting::CODE." do
    jaba(barebones: true) do
      shared :a do
      end
      BAD CODE # 138FA33C
    end
  end
end

jtest 'works when a there is a syntax error when definitions in a separate file' do
  fullpath = "#{temp_dir}/test.jaba"
  IO.write(fullpath, "\n\n&*^^\n")
  assert_jaba_error 'Syntax error at test.jaba:3: unexpected &' do
    jaba(barebones: true, src_root: temp_dir)
  end
end

jtest 'reports lines correctly when using shared modules' do
  assert_jaba_error "Error at #{src_loc('7F3590D4')}: 't.a' attribute invalid: 'invalid' is a string - expected [true|false]", trace: [__FILE__, '70A75502'] do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :bool
      end
      shared :s do
        a 'invalid' # 7F3590D4
      end
      test :t do
        include :s # 70A75502
      end
    end
  end
end

jtest 'allows errors to be raised from definitions' do
  assert_jaba_error "Error at #{src_loc('7FAC4085')}: Error msg." do
    jaba(barebones: true) do
      type :test do
        fail "Error msg" # 7FAC4085
      end
    end
  end
end

jtest 'supports core errors' do
  op = JABA.run(want_exceptions: false) do |c|
    JABA.error("an error occurred", want_backtrace: false)
  end
  op[:error].must_equal "an error occurred"

  op = JABA.run(want_exceptions: false) do |c|
    JABA.error("an error occurred", want_backtrace: true)
  end
  op[:error].must_match ":in `error': an error occurred (JABA::JabaError)\n\tfrom "

  e = assert_raises JABA::JabaError do
    JABA.run(want_exceptions: true) do |c|
      JABA.error("an error occurred", want_backtrace: true)
    end
  end
  e.message.must_equal('an error occurred')
  e.backtrace.empty?.must_equal(false)

  e = assert_raises JABA::JabaError do
    JABA.run(want_exceptions: true) do |c|
      JABA.error("an error occurred", want_backtrace: false)
    end
  end
  e.message.must_equal('an error occurred')
  
  # there is still a backtrace even though want_backtrace is false because want_backtrace
  # only affects jaba's return error not the exception.
  #
  e.backtrace.empty?.must_equal(false)
end
