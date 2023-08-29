jtest 'warns if dir not clean' do
  assert_jaba_warn "Directory 'a\\b' not specified cleanly: contains backslashes", __FILE__, 'F7B16193' do
    jaba(barebones: true) do
      type :test do
        attr :a, type: :dir do
          basedir_spec :definition_root
        end
      end
      test :t do
        a "a\\b" # F7B16193
      end
    end
  end
end

# TODO: test all base_dir specs

# TODO: test paths starting with ./

jtest 'rejects slashes in basename' do
  ['a\b', 'a/b'].each do |val|
    assert_jaba_error "Error at #{src_loc('D8744964')}: 't.a' attribute invalid: '#{val}' must not contain slashes." do
      jaba(barebones: true) do
        type :test do
          attr :a, type: :basename
        end
        test :t do
          a val # D8744964
        end
      end
    end
  end
end
