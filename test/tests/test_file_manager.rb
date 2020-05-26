# frozen_string_literal: true

module JABA

  using JABACoreExt

  class TestFileManager < JabaTest

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
