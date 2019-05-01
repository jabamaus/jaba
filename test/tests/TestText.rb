module JABA

class TestText < JabaTest

  describe 'text' do
=begin
    it 'can generate a text file' do
      fn = "#{temp_dir}/a"
      regenbuild do
        text_file :a do
          filename fn
          content 'b'
        end
      end
      file_exist?(fn).must_equal(true)
      IO.read(fn).must_equal('b')
    end
    
    it 'can generate a text file line by line' do
      fn = "#{temp_dir}/a"
      regenbuild do
        text_file :a do
          filename fn
          line 'b'
          line 'a'
          line 'b'
          line ['c', 'd']
        end
      end
      file_exist?(fn).must_equal(true)
      IO.read(fn).must_equal("b\na\nb\nc\nd\n")
    end
    
    it 'calls to_s on line items' do
      fn = "#{temp_dir}/a"
      regenbuild do
        text_file :a do
          filename fn
          line [1, 2, 3]
        end
      end
      file_exist?(fn).must_equal(true)
      IO.read(fn).must_equal("1\n2\n3\n")
    end
    
    it 'fails if no filename specified' do
      e = assert_raises DefinitionError do
        regenbuild do
          text_file :a do
          end
        end
      end
      e.message.must_match('\'filename\' property requires a value')
      e.definition_type.must_equal(:text_file)
      e.definition_id.must_equal(:a)
    end

    it 'can add src files to a text file' do
      make_file('a.cpp')
      make_file('b.cpp')
      fn = "#{temp_dir}/a"
      regenbuild(default_src: false) do
        text_file :a do
          filename fn
          line get_src_files('*')
        end
      end
      file_exist?(fn).must_equal(true)
      IO.read(fn).must_equal("a.cpp\nb.cpp\n")
    end
=end
  end

end

end
