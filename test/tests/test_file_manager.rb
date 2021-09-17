# frozen_string_literal: true

class TestFileManager < JabaTest

  it 'StringWriter can write line with newline' do
    sw = JABA::StringWriter.new(capacity: 100)
    sw << 'hello'
    sw.str.must_equal "hello\n"
    sw << 'world'
    sw.str.must_equal "hello\nworld\n"
  end
  
  it 'Stringwriter can write with no newline' do
    sw = JABA::StringWriter.new(capacity: 100)
    sw.write_raw 'hello'
    sw.str.must_equal 'hello'
    sw.write_raw 'world'
    sw.str.must_equal 'helloworld'
  end
  
  it 'Stringwriter can write blank lines' do
    sw = JABA::StringWriter.new(capacity: 100)
    sw << 'hello'
    sw.newline
    sw << 'world'
    sw.str.must_equal "hello\n\nworld\n"
  end
  
  it 'can write a file with native eol' do
    fn = "#{temp_dir}/f"
    fm = JABA::Services.new.file_manager
    f = fm.new_file(fn, eol: :native)
    w = f.writer
    w << 'test'
    f.write
    File.exist?(fn).must_equal(true)
    if JABA::OS.windows?
      IO.binread(fn).must_equal("test\r\n")
    else
      raise 'unsupported host OS'
    end
  end

  it 'can write a file with windows eol' do
    fn = "#{temp_dir}/f"
    fm = JABA::Services.new.file_manager
    f = fm.new_file(fn, eol: :windows)
    w = f.writer
    w << 'test'
    f.write
    File.exist?(fn).must_equal(true)
    IO.binread(fn).must_equal("test\r\n")
  end

  it 'can write a file with unix eol' do
    fn = "#{temp_dir}/f"
    fm = JABA::Services.new.file_manager
    f = fm.new_file(fn, eol: :unix)
    w = f.writer
    w << 'test'
    f.write
    File.exist?(fn).must_equal(true)
    IO.binread(fn).must_equal("test\n")
  end

  it 'detects invalid eol spec' do
    e = assert_raises do
      fn = "#{temp_dir}/f"
      fm = JABA::Services.new.file_manager
      fm.new_file(fn, eol: :undefined)
    end
    e.message.must_equal "':undefined' is an invalid eol style. Valid values: [:unix, :windows, :native]"
  end

  it 'detects duplicates' do
    fn = "#{temp_dir}/f"
    fm = JABA::Services.new.file_manager
    f = fm.new_file(fn)
    w = f.writer
    w << 'a'
    f.write
    File.exist?(fn).must_equal(true)
    f = fm.new_file(fn)
    w = f.writer
    w << 'b'
    assert_raises do
      f.write
    end.message.must_match(/Duplicate filename '.*' detected/)
  end

  it 'creates directories as necessary' do
    fn = "#{temp_dir}/a/b/c/d"
    File.exist?("#{temp_dir}/a").must_equal(false)
    fm = JABA::Services.new.file_manager
    f = fm.new_file(fn)
    w = f.writer
    w << 'a'
    f.write
    File.exist?(fn).must_equal(true)
  end

  it 'warns on writing empty file' do
    fn = "#{temp_dir}/f"
    s = JABA::Services.new
    fm = s.file_manager
    f = fm.new_file(fn)
    f.write
    s.instance_variable_get(:@warnings)[0].must_equal("Warning: '#{fn}' is empty")
    File.exist?(fn).must_equal(true)
    IO.read(fn).must_equal("")
  end

  # TODO: test encoding

  it 'maintains a list of generated files' do
    fns = ['a', 'b', 'c', 'd'].map{|f| "#{temp_dir}/#{f}"}
    s = JABA::Services.new
    fm = s.file_manager
    fns.each do |fn|
      f = fm.new_file(fn)
      f.write
    end
    fm.generated.must_equal fns
  end

  it 'detects when a file is newly created' do
    fn = "#{temp_dir}/f"
    File.exist?(fn).must_equal(false)
    s = JABA::Services.new
    fm = s.file_manager
    f = fm.new_file(fn)
    f.write
    File.exist?(fn).must_equal(true)
    fm.added.must_equal [fn]
  end

  it 'detects when a file is modified' do
    fn = "#{temp_dir}/f"
    File.exist?(fn).must_equal(false)
    IO.binwrite(fn, "test\r\n")
    s = JABA::Services.new
    fm = s.file_manager
    f = fm.new_file(fn, eol: :windows)
    w = f.writer
    w << "test2"
    f.write
    IO.binread(fn).must_equal("test2\r\n")
    fm.modified.must_equal [fn]
  end

  it 'detects when a file is modified by just eol' do
    fn = "#{temp_dir}/f"
    File.exist?(fn).must_equal(false)
    IO.binwrite(fn, "test\r\n")
    s = JABA::Services.new
    fm = s.file_manager
    f = fm.new_file(fn, eol: :unix)
    w = f.writer
    w << "test"
    f.write
    IO.binread(fn).must_equal("test\n")
    fm.modified.must_equal [fn]
  end
end
