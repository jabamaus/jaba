# frozen_string_literal: true

module JABA

  class TestText < JabaTest

    it 'can generate a text file' do
      fn = "#{temp_dir}/a"
      jaba do
        text :a do
          filename fn
          content 'b'
        end
      end
      File.exist?(fn).must_equal(true)
      IO.read(fn).must_equal('b')
    end

    it 'can generate a text file line by line' do
      fn = "#{temp_dir}/a"
      jaba do
        text :a do
          filename fn
          line 'b'
          line 'a'
          line 'b'
          line ['c', 'd']
        end
      end
      File.exist?(fn).must_equal(true)
      IO.read(fn).must_equal("b\na\nb\nc\nd\n")
    end
    
    it 'converts line items to strings' do
      fn = "#{temp_dir}/a"
      jaba do
        text :a do
          filename fn
          line [1, 2, 3]
        end
      end
      File.exist?(fn).must_equal(true)
      IO.read(fn).must_equal("1\n2\n3\n")
    end

    it 'fails if no filename specified' do
      check_fails("'filename' attribute requires a value",
                  trace: [__FILE__, '# tag1', CORE_TYPES_FILE, 'attr :filename, type: :file do']) do
        jaba do
          text :t do # tag1
          end
        end
      end
    end
=begin
    it 'can add src files to a text file' do
      make_file('a.cpp')
      make_file('b.cpp')
      fn = "#{temp_dir}/a"
      jaba(default_src: false) do
        text :a do
          filename fn
          line get_src_files('*')
        end
      end
      File.exist?(fn).must_equal(true)
      IO.read(fn).must_equal("a.cpp\nb.cpp\n")
    end
=end

  end

end
