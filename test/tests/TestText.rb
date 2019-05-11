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

=begin
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
    e = assert_raises JabaError do
      jaba do
        text :a do
        end
      end
    end
    e.message.must_match('\'filename\' property requires a value')
  end

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
