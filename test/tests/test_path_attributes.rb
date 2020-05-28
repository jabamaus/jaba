# frozen_string_literal: true

module JABA

  class TestPathAttributes < JabaTest

    describe 'dir attribute type' do
      
      it 'fails if dir is not clean' do
        check_warn "'a\\b' not specified cleanly. Should be 'a/b'", __FILE__, 'tagA' do
          jaba do
            define :test do
              attr :a, type: :dir
            end
            test :t do
              a "a\\b" # tagA
            end
          end
        end
      end

    end

  end

end
