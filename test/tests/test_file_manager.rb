# frozen_string_literal: true

module JABA

  using JABACoreExt

  class TestFileManager < JabaTest

    describe 'Stringwriter' do
      
      it 'can write line with newline' do
        sw = StringWriter.new(capacity: 100)
        sw << 'hello'
        sw.str.must_equal "hello\n"
        sw << 'world'
        sw.str.must_equal "hello\nworld\n"
      end
      
      it 'can write with no newline' do
        sw = StringWriter.new(capacity: 100)
        sw.write_raw 'hello'
        sw.str.must_equal 'hello'
        sw.write_raw 'world'
        sw.str.must_equal 'helloworld'
      end
      
      it 'can write blank lines' do
        sw = StringWriter.new(capacity: 100)
        sw << 'hello'
        sw.newline
        sw << 'world'
        sw.str.must_equal "hello\n\nworld\n"
      end

    end
    
    it 'can write a file' do
      fn = "#{temp_dir}/f"
      fm = Services.new.file_manager
      f = fm.new_file(fn)
      w = f.writer
      w << 'test'
      f.save
      File.exist?(fn).must_equal(true)
      IO.read(fn).must_equal("test\n")
    end

    it 'detects duplicates' do
      
    end

    # TODO: test eol
    # TODO: test encoding
  end

end
