# frozen_string_literal: true

module JABA

  using JABACoreExt

  class TestText < JabaTest

    TEXT_DEF_FILE = "#{__dir__}/../../lib/jaba/definitions/text.rb".cleanpath

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

    it 'appends line items to content' do
      fn = "#{temp_dir}/a"
      jaba do
        text :a do
          filename fn
          content "some\ncontent\n"
          line 'line3'
          line 'line4'
        end
      end
      File.exist?(fn).must_equal(true)
      IO.read(fn).must_equal("some\ncontent\nline3\nline4\n")
    end

    it 'fails if no filename specified' do
      check_fail "'filename' attribute requires a value. See #{TEXT_DEF_FILE}:#{find_line_number(TEXT_DEF_FILE, 'attr :filename')}", trace: [__FILE__, 'tagY'] do
        jaba do
          text :t # tagY
        end
      end
    end

  end

end
