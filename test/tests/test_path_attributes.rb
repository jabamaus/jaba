# frozen_string_literal: true

module JABA

  class TestPathAttributes < JabaTest

    it 'warns if dir not clean' do
      check_warn "Directory 'a\\b' not specified cleanly: contains backslashes", __FILE__, 'tagA' do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :dir do
              basedir_spec :definition_root
            end
          end
          test :t do
            a "a\\b" # tagA
          end
        end
      end
    end

    # TODO: test all base_dir specs

    # TODO: test paths starting with ./
  end

end
