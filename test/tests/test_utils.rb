# frozen_string_literal: true

module JABA

  class TestUtils < JabaTest
    
    describe 'Stringwriter' do
      
      it 'can write line with newline' do
        sw = StringWriter.new(capacity: 100)
        sw << 'hello'
        sw.must_equal "hello\n"
        sw << 'world'
        sw.must_equal "hello\nworld\n"
      end
      
      it 'can write with no newline' do
        sw = StringWriter.new(capacity: 100)
        sw.write_raw 'hello'
        sw.must_equal 'hello'
        sw.write_raw 'world'
        sw.must_equal 'helloworld'
      end
      
      it 'can write blank lines' do
        sw = StringWriter.new(capacity: 100)
        sw << 'hello'
        sw.newline
        sw << 'world'
        sw.must_equal "hello\n\nworld\n"
      end

    end
    
  end
  
end
