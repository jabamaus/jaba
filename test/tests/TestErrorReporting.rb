module JABA

class TestErrorReporting < JabaTest
  
  it 'provides exception information when a definition contains an error when definitions supplied in a block' do
    line = find_line_number(__FILE__, "category 'invalid id' do")
    e = check_fails("Error at TestErrorReporting.rb:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'",
                    backtrace: [[__FILE__, line]]) do
      jaba do
        category 'invalid id' do
        end
      end
    end
    e.cause.must_be_nil
  end

  it 'provides exception information when a definition contains an error when definitions supplied in a separate file' do
    fullpath = "#{temp_dir}/definitions.rb"
    IO.write(fullpath, "\n\ncategory 'invalid id' do\nend\n")
    line = 3
    e = check_fails("Error at definitions.rb:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'",
                    backtrace: [[fullpath, line]]) do
      jaba(load_paths: fullpath)
    end
    e.cause.must_be_nil
  end
  
  it 'provides exception information when a there is a syntax error when definitions supplied in a block' do
    line = find_line_number(__FILE__, 'bad code')
    e = check_fails("Error at TestErrorReporting.rb:#{line}: NameError: undefined local variable or method", backtrace: [[__FILE__, line]]) do
      jaba do
        shared :a do
        end
        bad code
      end
    end
    e.cause.wont_be_nil
  end

  it 'provides exception information when a there is a syntax error when definitions supplied in a separate file' do
    fullpath = "#{temp_dir}/definitions.rb"
    IO.write(fullpath, "\n\nbad code\n")
    line = 3
    e = check_fails("Error at definitions.rb:3: NameError: undefined local variable or method", backtrace: [[fullpath, 3]]) do
      jaba(load_paths: fullpath)
    end
    e.cause.wont_be_nil
  end
  
  it 'reports lines correctly when using shared modules' do
    # TODO
  end

end

end
