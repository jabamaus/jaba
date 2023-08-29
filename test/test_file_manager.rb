jtest "StringWriter can write line with newline" do
  sw = JABA::StringWriter.new
  sw << "hello"
  sw.str.must_equal "hello\n"
  sw << "world"
  sw.str.must_equal "hello\nworld\n"
end

jtest "Stringwriter can write with no newline" do
  sw = JABA::StringWriter.new
  sw.write_raw "hello"
  sw.str.must_equal "hello"
  sw.write_raw "world"
  sw.str.must_equal "helloworld"
end

jtest "Stringwriter can write blank lines" do
  sw = JABA::StringWriter.new
  sw << "hello"
  sw.newline
  sw << "world"
  sw.str.must_equal "hello\n\nworld\n"
end

jtest "can write a file with native eol" do
  fn = "#{temp_dir}/f"
  fm = JABA::Context.new.file_manager
  f = fm.new_file(fn, eol: :native)
  w = f.writer
  w << "test"
  f.write
  File.exist?(fn).must_be_true
  if JABA::OS.windows?
    IO.binread(fn).must_equal("test\r\n")
  else
    raise "unsupported host OS"
  end
end

jtest "can write a file with windows eol" do
  fn = "#{temp_dir}/f"
  fm = JABA::Context.new.file_manager
  f = fm.new_file(fn, eol: :windows)
  w = f.writer
  w << "test"
  f.write
  File.exist?(fn).must_be_true
  IO.binread(fn).must_equal("test\r\n")
end

jtest "can write a file with unix eol" do
  fn = "#{temp_dir}/f"
  fm = JABA::Context.new.file_manager
  f = fm.new_file(fn, eol: :unix)
  w = f.writer
  w << "test"
  f.write
  File.exist?(fn).must_be_true
  IO.binread(fn).must_equal("test\n")
end

jtest "detects invalid eol spec" do
  e = assert_raises JABA::JabaError do
    fn = "#{temp_dir}/f"
    fm = JABA::Context.new.file_manager
    fm.new_file(fn, eol: :undefined)
  end
  e.message.must_match "':undefined' is an invalid eol style. Valid values: [:unix, :windows, :native]"
end

jtest "can take a block" do
  fn = "#{temp_dir}/f"
  fm = JABA::Context.new.file_manager
  fm.new_file(fn) do |w|
    w << "a"
  end
  IO.read(fn).must_equal "a\n"
end

jtest "detects duplicates" do
  fn = "#{temp_dir}/f"
  fm = JABA::Context.new.file_manager
  f = fm.new_file(fn)
  w = f.writer
  w << "a"
  f.write
  File.exist?(fn).must_be_true
  IO.read(fn).must_equal("a\n")
  assert_jaba_error(/Duplicate filename '#{fn}' detected/) do
    fm.new_file(fn)
  end
end

jtest "creates directories as necessary" do
  fn = "#{temp_dir}/a/b/c/d"
  File.exist?("#{temp_dir}/a").must_be_false
  fm = JABA::Context.new.file_manager
  f = fm.new_file(fn)
  w = f.writer
  w << "a"
  f.write
  File.exist?(fn).must_be_true
end

jtest "warns on writing empty file" do
  fn = "#{temp_dir}/f"
  s = JABA::Context.new
  fm = s.file_manager
  f = fm.new_file(fn)
  f.write
  s.output[:warnings][0].must_equal("Warning: '#{fn}' is empty.")
  File.exist?(fn).must_be_true
  IO.read(fn).must_equal("")
end

# TODO: test encoding

jtest "maintains a list of generated files" do
  fns = ["a", "b", "c", "d"].map { |f| "#{temp_dir}/#{f}" }
  s = JABA::Context.new
  fm = s.file_manager
  fns.each do |fn|
    f = fm.new_file(fn)
    f.write
  end
  fm.generated.must_equal fns
end

jtest "detects when a file is newly created" do
  fn = "#{temp_dir}/f"
  File.exist?(fn).must_be_false
  s = JABA::Context.new
  fm = s.file_manager
  f = fm.new_file(fn)
  f.write
  File.exist?(fn).must_be_true
  fm.added.must_equal [fn]
end

jtest "detects when a file is modified" do
  fn = "#{temp_dir}/f"
  File.exist?(fn).must_be_false
  IO.binwrite(fn, "test\r\n")
  s = JABA::Context.new
  fm = s.file_manager
  f = fm.new_file(fn, eol: :windows)
  w = f.writer
  w << "test2"
  f.write
  IO.binread(fn).must_equal("test2\r\n")
  fm.modified.must_equal [fn]
end

jtest "detects when a file is modified by just eol" do
  fn = "#{temp_dir}/f"
  File.exist?(fn).must_be_false
  IO.binwrite(fn, "test\r\n")
  s = JABA::Context.new
  fm = s.file_manager
  f = fm.new_file(fn, eol: :unix)
  w = f.writer
  w << "test"
  f.write
  IO.binread(fn).must_equal("test\n")
  fm.modified.must_equal [fn]
end
