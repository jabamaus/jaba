# frozen_string_literal: true

class TestPathAttributes < JabaTest

  it 'warns if dir not clean' do
    assert_jaba_warn "Directory 'a\\b' not specified cleanly: contains backslashes", __FILE__, 'tagA' do
      jaba(barebones: true) do
        type :test do
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

  it 'rejects slashes in basename' do
    ['a\b', 'a/b'].each do |val|
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagB)}: 't.a' attribute invalid: '#{val}' must not contain slashes." do
        jaba(barebones: true) do
          type :test do
            attr :a, type: :basename
          end
          test :t do
            a val # tagB
          end
        end
      end
    end
  end

end
