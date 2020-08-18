# frozen_string_literal: true

module JABA

  class TestErrorReporting < JabaTest
    
    it 'works when a definition contains an error when definitions in a block' do
      line = find_line_number(__FILE__, 'tagR')
      check_fail "Error at test_error_reporting.rb:#{line}: 'invalid id' is an invalid id. Must be an " \
                     "alphanumeric string or symbol",
                     line: [__FILE__, line] do
        jaba do
          category 'invalid id' # tagR
        end
      end
    end

    it 'works when a definition contains an error when definitions in separate file' do
      fullpath = "#{temp_dir}/test.jaba"
      IO.write(fullpath, "\n\ncategory 'invalid id' do\nend\n")
      line = 3
      check_fail "Error at test.jaba:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric " \
                     "string or symbol",
                     line: [fullpath, line] do
        jaba(barebones: true, src_root: temp_dir)
      end
    end
    
    it 'works when a there is a syntax error when definitions in a block' do
      line = find_line_number(__FILE__, 'tagL')
      check_fail "Error at test_error_reporting.rb:#{line}", line: [__FILE__, line] do
        jaba(barebones: true) do
          shared :a do
          end
          BAD CODE # tagL
        end
      end
    end

    it 'works when a there is a syntax error when definitions in a separate file' do
      fullpath = "#{temp_dir}/test.jaba"
      IO.write(fullpath, "\n\n&*^^\n")
      check_fail 'Syntax error at test.jaba:3: unexpected &' do
        jaba(barebones: true, src_root: temp_dir)
      end
    end
    
    it 'reports lines correctly when using shared modules' do
      check_fail ':bool attributes only accept [true|false]', line: [__FILE__, 'tagH'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :bool
          end
          shared :s do
            a 'invalid' # tagH
          end
          test :t do
            include :s
          end
        end
      end
    end

    it 'allows errors to be raised from definitions' do
      check_fail 'Error msg', line: [__FILE__, 'tagW'] do
        jaba(barebones: true) do
          define :test do
            fail "Error msg" # tagW
          end
        end
      end
    end

  end

end
