# frozen_string_literal: true

module JABA

  class TestSrc < JabaTest

    # TODO: test case sensitivity
    
    it 'can be specified explicitly' do
      make_file('main.cpp')
      op = jaba(cpp_app: true) do
        cpp :a do
          src ['main.cpp']
        end
      end
      proj = op[:cpp]['cpp|a|vs2017|windows']
      proj.wont_be_nil
      proj[:src].must_equal(['main.cpp'])
    end

  end

end
