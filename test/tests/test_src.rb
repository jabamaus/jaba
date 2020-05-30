# frozen_string_literal: true

module JABA

  class TestSrc < JabaTest

    # TODO: test case sensitivity
    # TODO: validate that src files are not absolute. Could be an attribute flag

    it 'can be specified explicitly even if extension is not in src_ext' do
      make_file('main.cpp', 'file.z')
      op = jaba(cpp_app: true) do
        cpp :a do
          src ['main.cpp', 'file.z']
        end
      end
      proj = op[:cpp]['cpp|a|vs2017|windows']
      proj.wont_be_nil
      proj[:src].must_equal(['file.z', 'main.cpp'])
    end

    it 'fails if explicitly specified files do not exist unless forced' do
      check_fail "'main.cpp' does not exist on disk. Use :force to add anyway", trace: [__FILE__, 'tagA'] do
        jaba(cpp_app: true) do
          cpp :a do
            src 'main.cpp' # tagA
          end
        end
        op = jaba(cpp_app: true) do
          cpp :a do
            src 'main.cpp', :force
          end
        end
        proj = op[:cpp]['cpp|a|vs2017|windows']
        proj.wont_be_nil
        proj[:src].must_equal(['main.cpp'])
      end

    end

  end

end
