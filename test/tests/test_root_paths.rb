# frozen_string_literal: true

module JABA

  using JABACoreExt

  class TestRootPaths < JabaTest

    def each_src_root_build_root
      sr = "#{temp_dir}/src_root"
      FileUtils.mkdir(sr)
      IO.write("#{sr}/test.jaba", "")

      src_roots = [
        "#{JABA.examples_dir}/01-basic_app",
        "#{JABA.examples_dir}/01-basic_app/basic_app.jaba" # src_root can also be a .jaba file
      ]

      build_roots = [
        "#{sr}/../build_root1".cleanpath,  # test build_root being next to src_root
        "#{sr}/build_root2",               # test build_root being inside src_root
        "#{sr}/nested/build_root3"         # test build_root being nested inside src_root
      ]
 
      yield sr, sr # test build_root and src_root being the same
      src_roots.each do |s|
        File.exist?(s).must_equal(true, "#{s} does not exist")
        build_roots.each do |b|
          yield s, "#{b}_#{s.basename}"
        end
      end
    end

    def check_src_and_build_root(op, sr, br)
      services = op[:services]
      services.input.src_root.must_equal(sr)
      services.input.build_root.must_equal(br)
      
      File.exist?("#{br}/.jaba").must_equal(true)
      File.exist?("#{br}/.jaba/jaba.output.vs2019.json").must_equal(true)
      File.exist?("#{br}/.jaba/src_root.cache").must_equal(true)
      IO.read("#{br}/.jaba/src_root.cache").must_equal("src_root=#{sr}")

      # check that jaba can be rerun inside build_root without src_root being set
      #
      Dir.chdir(br) do
        JABA.run
      end
      JABA.run do |c|
        c.build_root = br
      end

      # Check that attempts to change src_root once cached fail
      #
      op = JABA.run(want_exceptions: false) do |c|
        c.build_root = br
        c.src_root = "#{JABA.examples_dir}/02-basic_static_lib"
        c.argv = ['-D', 'target_host=vs2019']
      end
      op[:error].must_equal("Source root already set to '#{sr}' - cannot change")

      op = JABA.run(want_exceptions: false) do |c|
        c.build_root = br
        c.argv = ['-S', "#{JABA.examples_dir}/02-basic_static_lib"]
      end
      op[:error].must_equal("Source root already set to '#{sr}' - cannot change")
    end

    it 'checks src_root is valid' do
      sr = "#{temp_dir}/src_root"
      br = "#{temp_dir}/build_root"
      op = JABA.run do |c|
        c.src_root = sr
        c.build_root = br
      end
      op[:error].must_equal "source root '#{sr}' does not exist"

      FileUtils.mkdir(sr)
      op = JABA.run do |c|
        c.src_root = sr
        c.build_root = br
      end
      op[:error].must_equal "No .jaba files found in '#{sr}'"

      # test a nested .jaba file. Should not find it because search is not recursivetj
      #
      FileUtils.mkdir("#{sr}/nested")
      IO.write("#{sr}/nested/test.jaba", "")

      op = JABA.run do |c|
        c.src_root = sr
        c.build_root = br
      end
      op[:error].must_equal "No .jaba files found in '#{sr}'"
    end

    it 'defaults build_root to cwd' do
      sr = "#{temp_dir}/src_root"
      FileUtils.mkdir(sr)
      IO.write("#{sr}/test.jaba", "")
      op = nil
      Dir.chdir(sr) do
        op = JABA.run do |c|
          c.argv = ['-D', 'target_host=vs2019']
          c.src_root = sr
        end
      end
      check_src_and_build_root(op, sr, sr)
    end

    it 'supports specifying src_root and build_root in jaba input' do
      each_src_root_build_root do |sr, br|
        op = JABA.run do |c|
          c.argv = ['-D', 'target_host=vs2019']
          c.src_root = sr
          c.build_root = br
        end
        check_src_and_build_root(op, sr, br)
      end
    end

    it 'supports specifying src_root and build_root on cmd line' do
      each_src_root_build_root do |sr, br|
        op = JABA.run do |c|
          c.argv = ['--src-root', sr, '--build-root', br, '-D', 'target_host=vs2019']
        end
        check_src_and_build_root(op, sr, br)
      end
    end

  end

end
