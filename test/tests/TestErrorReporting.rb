module JABA

class TestErrorReporting < JabaTest
  
  describe 'Error reporting' do
    
    it 'provides exception information when a definition contains an error when definitions supplied in a block' do
      e = assert_raises DefinitionError do
        jaba do
          category 'invalid id' do
          end
        end
      end
      e.file.must_equal(__FILE__)
      line = find_line_number('category \'invalid id\' do', __FILE__)
      e.line.must_equal(line)
      e.message.must_equal("Definition error at TestErrorReporting.rb:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'")
      e.definition_type.must_equal(:category)
      e.definition_id.must_equal('invalid id')
      e.where.must_equal("at TestErrorReporting.rb:#{line}")
    end

    it 'provides exception information when a definition contains an error when definitions supplied in a separate file' do
      fullpath = "#{temp_dir}/TestErrorReporting1.rb"
      IO.write(fullpath, "\n\ncategory 'invalid id' do\nend\n")
      e = assert_raises DefinitionError do
        jaba(load_paths: fullpath)
      end
      e.file.must_equal(fullpath)
      line = 3
      e.line.must_equal(line)
      e.message.must_equal("Definition error at TestErrorReporting1.rb:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'")
      e.definition_type.must_equal(:category)
      e.definition_id.must_equal('invalid id')
      e.where.must_equal("at TestErrorReporting1.rb:#{line}")
    end
    
    it 'provides exception information when a there is a syntax error when definitions supplied in a block' do
      e = assert_raises DefinitionError do
        jaba do
          shared :a do
          end
          bad code
        end
      end
      e.file.must_equal(__FILE__)
      line = find_line_number('bad code', __FILE__)
      e.line.must_equal(line)
      e.definition_type.must_be_nil
      e.definition_id.must_be_nil
      e.where.must_equal("at TestErrorReporting.rb:#{line}")
    end

    it 'provides exception information when a there is a syntax error when definitions supplied in a separate file' do
      fullpath = "#{__dir__}/temp/TestErrorReporting2.rb"
      IO.write(fullpath, "\n\nbad code\n")
      e = assert_raises DefinitionError do
        jaba(load_paths: fullpath)
      end
      e.file.must_equal(fullpath)
      line = 3
      e.line.must_equal(line)
      e.definition_type.must_be_nil
      e.definition_id.must_be_nil
      e.where.must_equal("at TestErrorReporting2.rb:#{line}")
    end
    
  end
  
  it 'reports lines correctly when using shared modules' do
    # TODO
  end
  
end

end
