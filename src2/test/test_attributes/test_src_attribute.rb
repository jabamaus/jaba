# TODO: test case sensitivity
# TODO: only array supports wildcards

jtest "warns if src not specified cleanly" do
  make_file("a/b.cpp")
  jdl do
    attr :src, type: :src
  end
  op = jaba(want_exceptions: false) do
    src "a\\b.cpp", :force # 21957B5D
  end
  op[:error].must_be_nil
  w = op[:warnings]
  w.size.must_equal 1
  w[0].must_equal "Warning at #{src_loc("21957B5D")}: 'src' attribute not specified cleanly: 'a\\b.cpp' contains backslashes."
end

jtest "can be specified explicitly even if extension is not in src_ext" do
  make_file("a.cpp", "b.z", "c.z")
  jdl(level: :core) do
    attr :src, variant: :array, type: :src
  end
  str = %q{
    src ["a.cpp", "b.z"]
    src.must_equal ["#{__dir__}/a.cpp", "#{__dir__}/b.z"]
  }
  make_file("test1.jaba", content: str)
  op = jaba(src_root: "#{temp_dir}/test1.jaba").check(warnings: [], error: nil)
  op[:root][:src][0].must_equal "#{temp_dir}/a.cpp"
  op[:root][:src][1].must_equal "#{temp_dir}/b.z"

  # Glob match can work without extension being in src_ext as long as the extension is specified
  str = %q{
    src ['*.z']
    src.must_equal ["#{__dir__}/b.z", "#{__dir__}/c.z"]
  }
  make_file("test2.jaba", content: str)
  op = jaba(src_root: "#{temp_dir}/test2.jaba").check(warnings: [], error: nil)
  op[:root][:src][0].must_equal "#{temp_dir}/b.z"
  op[:root][:src][1].must_equal "#{temp_dir}/c.z"
end

jtest "fails if explicitly specified files do not exist unless forced" do
  jdl do
    attr :src, variant: :array, type: :src
  end
  dir = __dir__
  op = jaba do
    src ["a.cpp"], :force
    JTest.assert_jaba_error "Error at #{JTest.src_loc("5CC0FC29")}: '#{dir}/b.cpp' does not exist on disk - use :force to add anyway." do
      src ["b.cpp"] # 5CC0FC29
    end
  end.check(warnings: [])
  op[:root][:src][0].must_equal("#{__dir__}/a.cpp")

  #proj = jaba(cpp_app: true, dry_run: true) do
  #  cpp :app do
  #    project do
  #      src ['main.cpp'], :force
  #    end
  #  end
  #end
  #proj[:src].must_equal ["#{temp_dir}/main.cpp"]
end
=begin
jtest 'disallows wildcards when force adding src' do
  make_file('a/a.cpp')
  assert_jaba_error "Error at #{src_loc('0042DF50')}: Wildcards are not allowed when force adding src - only explicitly specified source files." do
    jaba(cpp_app: true, dry_run: true) do
      cpp :app do
        project do
          src ['a/*.*'], :force # 0042DF50
          src ['b.cpp'], :force
        end
      end
    end
  end
end

jtest 'supports adding files beginning with dot but only explicitly' do
  make_file('.a', 'b/.cpp', 'c.cpp')
  assert_jaba_warn "'#{temp_dir}/b/*' did not match any src files", __FILE__, '0C6730D4' do
    proj = jaba(cpp_app: true, dry_run: true) do
      cpp :app do
        project do
          src ['b/*'] # 0C6730D4
          src ['.a']
        end
      end
    end
    proj[:src].must_equal ["#{temp_dir}/.a"]
  end
end

jtest 'supports adding src with absolute paths' do
  make_file('a.cpp')
  fn = "#{temp_dir}/a.cpp"
  proj = jaba(cpp_app: true, dry_run: true) do
    cpp :app do
      project do
        src [fn]
      end
    end
  end
  proj[:src].must_equal ["#{temp_dir}/a.cpp"]
end

jtest 'supports adding src relative to jaba file or root' do
  r = "#{temp_dir}/a"
  proj = jaba(cpp_app: true, dry_run: true) do
    cpp :app do
      root r
      project do
        src ['./missing.rb'], :force
        src ['missing.rb'], :force
        src ['./b.cpp'], :force # force relative to this definition file (this src file) rather than root
        src ['./test_e*.rb'] # extension explicitly specified even though .rb not a cpp file type so will be added
        src ['./test_*.*'] # nothing will be added because glob will not match any cpp file extensions
        src ['../missing.rb'], :force
        src ['b/c.cpp'], :force
        src ['./a/b/c.cpp'], :force
      end
      config do
        vcfprop './missing.rb|Foo', 'bar'
        vcfprop 'missing.rb|Foo', 'bar'
        vcfprop './b.cpp|Foo', 'bar'
      end
    end
  end

  proj[:src].must_equal [
    "#{__dir__}/missing.rb",
    "#{temp_dir}/a/missing.rb",
    "#{__dir__}/b.cpp",
    "#{__dir__}/test_error_reporting.rb",
    "#{__dir__}/test_export_system.rb",
    "#{__dir__}/test_extension_semantics.rb",
    "#{temp_dir}/missing.rb",
    "#{temp_dir}/a/b/c.cpp",
    "#{__dir__}/a/b/c.cpp",
  ].sort
end

jtest 'supports adding whole src directories recursively' do
  make_file('a/b.cpp', 'a/c.cpp', 'a/d.cpp', 'a/e/f/g.cpp')
  make_file('dir.with.dots/a/h.cpp')
  make_file('dir.with.dots/b/h.xyz')
  make_file('a/b.z') # won't match as .z not in src_ext attr
  proj = jaba(cpp_app: true, dry_run: true) do
    cpp :app do
      project do
        src ['a']
        src ['dir.with.dots']
      end
    end
  end
  proj[:src].must_equal [
    "#{temp_dir}/a/b.cpp",
    "#{temp_dir}/a/c.cpp",
    "#{temp_dir}/a/d.cpp",
    "#{temp_dir}/a/e/f/g.cpp",
    "#{temp_dir}/dir.with.dots/a/h.cpp"
  ].sort
end

jtest 'supports platform-specific default src extensions' do
  make_file('a.cpp', 'b.natvis', 'c.xcconfig', 'e.def', 'f.rc')
  td = temp_dir
  op = jaba(dry_run: true, global_attrs: {target_host: 'vs2019'}) do
    cpp :app do
      root td
      platforms [:windows_x86, :windows_x86_64, :ios_arm64]
      project do
        type :app
        configs [:Debug, :Release]
        src ['*']
      end
    end
  end
  vsproj = op[:cpp]['app|windows']
  vsproj.wont_be_nil

  vsproj[:src].must_equal [
    "#{temp_dir}/a.cpp",
    "#{temp_dir}/b.natvis",
    "#{temp_dir}/e.def",
    "#{temp_dir}/f.rc"
  ]

  op = jaba(dry_run: true, global_attrs: {target_host: 'xcode'}) do
    cpp :app do
      root td
      platforms [:windows_x86, :windows_x86_64, :ios_arm64]
      project do
        type :app
        configs [:Debug, :Release]
        src ['*']
      end
    end
  end
  xcodeproj = op[:cpp]['app|ios']
  xcodeproj.wont_be_nil
  
  xcodeproj[:src].must_equal [
    "#{temp_dir}/a.cpp",
    "#{temp_dir}/c.xcconfig"
  ]
end

jtest 'supports adding custom extensions' do
  make_file('a/b.cpp', 'a/c.cpp', 'a/d.cpp', 'a/e/f/g.cpp')
  make_file('a/b.z', 'a/e/f/g/h.y')
  proj = jaba(cpp_app: true, dry_run: true) do
    cpp :app do
      project do
        src_ext ['.z', '.y']
        src ['a']
      end
    end
  end
  proj[:src].must_equal [
    "#{temp_dir}/a/b.cpp",
    "#{temp_dir}/a/b.z",
    "#{temp_dir}/a/c.cpp",
    "#{temp_dir}/a/d.cpp",
    "#{temp_dir}/a/e/f/g.cpp",
    "#{temp_dir}/a/e/f/g/h.y"
  ]
end

jtest 'supports glob matches' do
  make_file('a.cpp', 'b.cpp', 'c/d.cpp', 'd/e/f/g.cpp')
  proj = jaba(cpp_app: true, dry_run: true) do
    cpp :app do
      project do
        src ['*'] # should not recurse
      end
    end
  end
  proj[:src].must_equal [
    "#{temp_dir}/a.cpp",
    "#{temp_dir}/b.cpp"
  ]
  proj = jaba(cpp_app: true, dry_run: true) do
    cpp :app do
      project do
        src ['**/*'] # should match everything
      end
    end
  end
  proj[:src].must_equal [
    "#{temp_dir}/a.cpp",
    "#{temp_dir}/b.cpp",
    "#{temp_dir}/c/d.cpp",
    "#{temp_dir}/d/e/f/g.cpp"
  ]
end
=end
jtest "strips duplicate src" do
  jdl do
    attr :src, variant: :array, type: :src
  end
  # It strips items that are exactly the same, and warns
  op = jaba do
    src ["a.cpp", "a.cpp"], :force # BFE9E793
  end
  op[:warnings].must_equal ["Warning at #{src_loc("BFE9E793")}: Stripping duplicates [\"#{__dir__}/a.cpp\"] from 'src' attribute."]
  op[:error].must_be_nil
  # It strips files that match different specs
  make_file("a/a.cpp", "a/a.h")
  #proj = jaba(cpp_app: true, dry_run: true) do
  #  cpp :app do
  #    project do
  #      src ["a"]
  #      src ["**/*.h"]
  #    end
  #  end
  #end
  #proj[:src].must_equal [
  #  "#{temp_dir}/a/a.cpp",
  #  "#{temp_dir}/a/a.h",
  #]
end

jtest "supports excludes" do
  files = ['a.cpp', 'b.cpp', 'c.cpp', 'd.x', 'e.y', 'a/b/e.cpp', 'a/b/h.y', 'b/c/d.cpp']
  make_file(*files)
  td = temp_dir
  jdl(level: :core) do
    node :node
    attr "node/src", variant: :array, type: :src do
      base_attr :root
    end
  end
  jaba do
    node :n, root: td do
      src ['a.cpp', 'b.cpp', 'c.cpp', 'd.x', 'e.y', 'a/b/e.cpp', 'a/b/h.y', 'b/c/d.cpp']
      src exclude: [
        'b.cpp', # exclude explicit file
        '*.x', # exclude with glob match 
        'a/**/*.cpp', # exclude with glob match recursively
        'b' # exclude whole dir. Equivalent to b/**/*
      ]
      src.must_equal [
        "#{td}/a.cpp",
        "#{td}/c.cpp", 
        "#{td}/e.y",
        "#{td}/a/b/h.y",
      ]
    end
  end
end
