# frozen_string_literal: true

module JABA

  class TestErrorReporting < JabaTest
    
    it 'works when a definition contains an error when definitions in a block' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagR)}: 'invalid id' is an invalid id. Must be an " \
                     "alphanumeric string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'." do
        jaba do
          category 'invalid id' # tagR
        end
      end
    end

    it 'works when a definition contains an error when definitions in separate file' do
      fullpath = "#{temp_dir}/test.jaba"
      IO.write(fullpath, "\n\ncategory 'invalid id' do\nend\n")
      line = 3
      assert_jaba_error "Error at test.jaba:#{line}: 'invalid id' is an invalid id. Must be an alphanumeric " \
                     "string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'." do
        jaba(barebones: true, src_root: temp_dir)
      end
    end
    
    it 'works when a there is a standard error when definitions in a block' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagL)}: uninitialized constant JABA::TestErrorReporting::CODE." do
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
      assert_jaba_error 'Syntax error at test.jaba:3: unexpected &' do
        jaba(barebones: true, src_root: temp_dir)
      end
    end
    
    it 'reports lines correctly when using shared modules' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagH)}: 't.a' attribute invalid: :bool attributes only accept [true|false] but got 'invalid'.", trace: [__FILE__, :tagh] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :bool
          end
          shared :s do
            a 'invalid' # tagH
          end
          test :t do
            include :s # tagh
          end
        end
      end
    end

    it 'allows errors to be raised from definitions' do
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagW)}: Error msg." do
        jaba(barebones: true) do
          define :test do
            fail "Error msg" # tagW
          end
        end
      end
    end

  end

end
