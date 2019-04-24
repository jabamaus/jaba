module JABA

class TestErrorReporting < JabaTestCase
  
  def find_line_number(string, file=__FILE__)
    IO.read(file).each_line.find_index {|line| line.include?(string)} + 1
  end
  
  describe 'Error reporting' do
    
    it 'provides exception information when a definition contains an error when definitions supplied in a block' do
      e = assert_raises DefinitionError do
        jaba do
          category 'invalid id' do
          end
        end
      end
      e.file.must_equal(__FILE__)
      line = find_line_number('category \'invalid id\' do')
      e.line.must_equal(line)
      e.message.must_equal("Definition error at TestErrorReporting.rb:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'")
      e.definition_type.must_equal(:category)
      e.definition_id.must_equal('invalid id')
      e.where.must_equal("at TestErrorReporting.rb:#{line}")
    end
=begin
    it 'provides exception information when a there is a syntax error' do
      e = assert_raises DefinitionError do
        jaba do
          shared :a do
          end
          categ ory :b do
          end
        end
      end
      #e.file.must_equal(__FILE__)
      line = find_line_number('categ ory :b do')
      e.line.must_equal(line)
      e.definition_type.must_equal(nil)
      e.definition_id.must_equal(nil)
      e.message.must_equal("Definition error at TestErrorReporting.rb:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'")
      e.where.must_equal("at TestErrorReporting.rb:#{line}")
    end
=end
    it 'provides exception information when a definition contains an error when definitions supplied in a separate file' do
      fullpath = "#{__dir__}/temp/TestErrorReportingDefinitions.rb"
      IO.write(fullpath, "\n\ncategory 'invalid id' do\nend\n")
      e = assert_raises DefinitionError do
        jaba(load_paths: fullpath)
      end
      e.file.must_equal(fullpath)
      line = 3
      e.line.must_equal(line)
      e.message.must_equal("Definition error at TestErrorReportingDefinitions.rb:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'")
      e.definition_type.must_equal(:category)
      e.definition_id.must_equal('invalid id')
      e.where.must_equal("at TestErrorReportingDefinitions.rb:#{line}")
    end
  end
  
  it 'reports lines correctly when using shared modules' do
    # TODO
  end
  
end

end
