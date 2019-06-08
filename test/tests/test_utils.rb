# frozen_string_literal: true

module JABA

  class TestUtils < JabaTest
    
    describe 'Stringwriter' do
      
      it 'can write line with newline' do
        sw = StringWriter.new(capacity: 100)
        sw.write 'hello'
        sw.str.must_equal "hello\n"
        sw.write 'world'
        sw.str.must_equal "hello\nworld\n"
      end
      
      it 'can write with no newline' do
        sw = StringWriter.new(capacity: 100)
        sw.write_raw 'hello'
        sw.str.must_equal 'hello'
        sw.write_raw 'world'
        sw.str.must_equal 'helloworld'
      end
      
      it 'can write blank lines' do
        sw = StringWriter.new(capacity: 100)
        sw.write 'hello'
        sw.newline
        sw.write 'world'
        sw.str.must_equal "hello\n\nworld\n"
      end
      
      it 'supports sub buffers' do
        sw = StringWriter.new(capacity: 100)
        sw.write 'hello'
        sb = sw.sub_buffer do
          sw.write 'happy'
          sw.write 'world'
          sb2 = sw.sub_buffer do
            sw.write 'good'
            sw.write 'morning'
          end
          sb2.must_equal "good\nmorning\n"
          sw.write_raw(sb2)
        end
        
        sb.must_equal "happy\nworld\ngood\nmorning\n"
        sw.str.must_equal "hello\n"
        sw.write_raw(sb)
        sw.str.must_equal "hello\nhappy\nworld\ngood\nmorning\n"
      end
      
    end
    
  end
  
end
