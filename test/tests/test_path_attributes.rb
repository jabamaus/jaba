# frozen_string_literal: true

module JABA

  class TestPathAttributes < JabaTest

    it 'warns if dir not clean' do
      check_warn "Directory 'a\\b' not specified cleanly: contains backslashes", __FILE__, 'tagA' do
        jaba(barebones: true) do
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
