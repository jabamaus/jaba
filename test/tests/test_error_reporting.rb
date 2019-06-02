module JABA

  class TestErrorReporting < JabaTest
    
    it 'works when a definition contains an error when definitions in a block' do
      line = find_line_number(__FILE__, 'tag1')
      e = check_fails("Error at test_error_reporting.rb:#{line}: 'invalid id' is an invalid id. Must be an " \
                      "alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'",
                      trace: [__FILE__, line]) do
        jaba do
          category 'invalid id' do # tag1
          end
        end
      end
      e.cause.must_be_nil
    end

    it 'works when a definition contains an error when definitions in separate file' do
      fullpath = "#{temp_dir}/definitions.rb"
      IO.write(fullpath, "\n\ncategory 'invalid id' do\nend\n")
      line = 3
      e = check_fails("Error at definitions.rb:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric " \
                      "string or symbol (underscore permitted), eg :my_id or 'my_id'",
                      trace: [fullpath, line]) do
        jaba(load_paths: fullpath)
      end
      e.cause.must_be_nil
    end
    
    it 'works when a there is a syntax error when definitions in a block' do
      line = find_line_number(__FILE__, '# tag2')
      e = check_fails("Syntax error at test_error_reporting.rb:#{line}", trace: [__FILE__, line]) do
        jaba do
          shared :a do
          end
          BAD CODE # tag2
        end
      end
      e.cause.wont_be_nil
    end

    it 'works when a there is a syntax error when definitions in a separate file' do
      fullpath = "#{temp_dir}/definitions.rb"
      IO.write(fullpath, "\n\nBAD CODE\n")
      line = 3
      e = check_fails("Syntax error at definitions.rb:3", trace: [fullpath, 3]) do
        jaba(load_paths: fullpath)
      end
      e.cause.wont_be_nil
    end
    
    it 'reports lines correctly when using shared modules' do
      # TODO
    end

  end

end
