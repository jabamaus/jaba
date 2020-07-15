# frozen_string_literal: true

module JABA

  class TestSrc < JabaTest

    # TODO: test case sensitivity

    it 'warns if src not specified cleanly' do
      make_file('a.cpp')
      check_warn "Src spec 'a/../b/c/../../' not specified cleanly. Should be '.'", __FILE__, 'tagW' do
        jaba(cpp_app: true, dry_run: true) do
          cpp :app do
            src ['a.cpp', 'a/../b/c/../../'] # tagW
          end
        end
      end
    end

    it 'can be specified explicitly even if extension is not in src_ext' do
      make_file('a.cpp', 'b.z')
      proj = jaba(cpp_app: true, dry_run: true) do
        cpp :app do
          src ['a.cpp', 'b.z']
        end
      end
      proj[:src].must_equal(['a.cpp', 'b.z'])
    end

    it 'fails if explicitly specified files do not exist unless forced' do
      check_fail "'a.cpp' does not exist on disk. Use :force to add anyway", line: [__FILE__, 'tagA'] do
        jaba(cpp_app: true, dry_run: true) do
          cpp :app do
            src ['a.cpp'] # tagA
          end
        end
        proj = jaba(cpp_app: true, dry_run: true) do
          cpp :app do
            src ['a.cpp'], :force
          end
        end
        proj[:src].must_equal(['main.cpp'])
      end
    end

    it 'disallows wildcards when force adding src' do
      make_file('a/a.cpp')
      check_fail "Wildcards are not allowed when force adding src - only explicitly specified source files",
                line: [__FILE__, 'tagB'] do
        jaba(cpp_app: true, dry_run: true) do
          cpp :app do
            src ['a/*.*'], :force # tagB
          end
        end
      end
    end

    it 'supports adding files beginning with dot but only explicitly' do
      make_file('.a', 'b/.cpp')
      check_warn "'b/*' did not match any src files", __FILE__, 'tagF' do
        proj = jaba(cpp_app: true, dry_run: true) do
          cpp :app do
            src ['.a', 'b/*'] # tagF
          end
        end
        proj[:src].must_equal(['.a'])
      end
    end

    it 'supports adding src with absolute paths' do
      make_file('a.cpp')
      fn = "#{temp_dir}/a.cpp"
      proj = jaba(cpp_app: true, dry_run: true) do
        cpp :app do
          src [fn]
        end
      end
      proj[:src].must_equal(['a.cpp'])
    end

    it 'supports adding whole src directories recursively' do
      make_file('a/b.cpp', 'a/c.cpp', 'a/d.cpp', 'a/e/f/g.cpp')
      make_file('a/b.z') # won't match as .z not in src_ext attr
      proj = jaba(cpp_app: true, dry_run: true) do
        cpp :app do
          src ['a']
        end
      end
      proj[:src].must_equal(['a/b.cpp', 'a/c.cpp', 'a/d.cpp', 'a/e/f/g.cpp'])
    end

    it 'supports platform-specific default src extensions' do
      make_file('a.cpp', 'b.natvis', 'c.xcconfig', 'e.def', 'f.rc')
      td = temp_dir
      op = jaba(dry_run: true) do
        cpp :app do
          type :app
          root td
          hosts [:vs2019], platforms: [:windows_x86, :windows_x86_64]
          hosts [:xcode], platforms: [:ios_arm64]
          configs [:Debug, :Release]
          src ['*']
        end
      end
      vsproj = op[:cpp]['app|vs2019|windows']
      vsproj.wont_be_nil
      vsproj[:src].must_equal ['a.cpp', 'b.natvis', 'e.def', 'f.rc']
      xcodeproj = op[:cpp]['app|xcode|ios']
      xcodeproj.wont_be_nil
      xcodeproj[:src].must_equal ['a.cpp', 'c.xcconfig']
    end

    it 'supports adding custom extensions' do
      make_file('a/b.cpp', 'a/c.cpp', 'a/d.cpp', 'a/e/f/g.cpp')
      make_file('a/b.z', 'a/e/f/g/h.y')
      proj = jaba(cpp_app: true, dry_run: true) do
        cpp :app do
          src_ext ['.z', '.y']
          src ['a']
        end
      end
      proj[:src].must_equal(['a/b.cpp', 'a/b.z', 'a/c.cpp', 'a/d.cpp', 'a/e/f/g.cpp', 'a/e/f/g/h.y'])
    end

    it 'supports glob matches' do
      make_file('a.cpp', 'b.cpp', 'c/d.cpp', 'd/e/f/g.cpp')
      proj = jaba(cpp_app: true, dry_run: true) do
        cpp :app do
          src ['*'] # should not recurse
        end
      end
      proj[:src].must_equal ['a.cpp', 'b.cpp']
    end

    # TODO: test fail when no src file matches
  end

end
