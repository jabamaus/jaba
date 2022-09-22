jtest 'rejects invalid ids' do
  [:cpp, :shared, :type].each do |item|
    jaba(dry_run: true) do
      case item
      when :cpp
        defaults :cpp do
          platforms [:windows_x86]
          project do
            type :app
            configs [:debug, :release]
            src 'main.cpp', :force
          end
        end
      end
      __send__(item, :Alpha_Num3r1cs_With_Underscores_Are_Valid_Everything_Else_Is_Not) do
      end
      __send__(item, 'Str1ngs_also_allowed') do
      end
      __send__(item, 'this.is.valid') do
      end
      __send__(item, 'this-is-valid') do
      end
    end
    
    errmsg = "Must be an alphanumeric string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'."
    assert_jaba_error "Error at #{src_loc('FB9E5848')}: 'Space invalid' is an invalid id. #{errmsg}" do
      jaba(barebones: true) do
        __send__(item, 'Space invalid') do # FB9E5848
        end
      end
    end
    
    assert_jaba_error "Error at #{src_loc('F824AAC9')}: '1' is an invalid id. #{errmsg}" do
      jaba(barebones: true) do
        __send__(item, 1) do # F824AAC9
        end
      end
    end

    assert_jaba_error "Error at #{src_loc('9E1AA44C')}: '#{item}' requires an id. #{errmsg}" do
      jaba(barebones: true) do
        __send__(item) do # 9E1AA44C
        end
      end
    end
  end
end

jtest 'detects duplicate ids with definitions of the same type' do
  [:cpp, :defaults, :type, :shared, :text, :workspace].each do |item|
    assert_jaba_error "Error at #{src_loc('112FB455')}: '#{item}|a' multiply defined. First definition at #{src_loc('32EC8A5C')}." do
      jaba do
        __send__(item, :a) do # 32EC8A5C
        end
        __send__(item, :a) do # 112FB455
        end
      end
    end
  end
end

jtest 'allows different types to have the same id' do
  jaba(cpp_app: true, dry_run: true) do
    shared :a do
    end
    cpp :app do
      project do
        src ['a.cpp'], :force
      end
    end
    workspace :a do
      projects [:app]
    end
  end
end

jtest 'allows definition id to be accessed from all definitions' do
  jaba(barebones: true) do
    type :test do
      id.must_equal(:test)
      attr :b do
        id.must_equal(:b)
      end
    end
    open_type :test do
      id.must_equal(:test)
    end
    defaults :test do
      id.must_equal(:a) # :a not :test
    end
    shared :s do
      id.must_equal(:a) # :a not :s
    end
    test :a do
      include :s
      id.must_equal(:a)
    end
  end
end

jtest 'instances types in order of definition' do
  assert_output 'a;1;2;3;' do
    jaba(barebones: true) do
      a :a do
        print '1;'
      end
      a :b do
        print '2;'
      end
      a :c do
        print '3;'
      end
      type :a do
        print 'a;'
      end
    end
  end
end

jtest 'rejects attempts to instance an unknown type' do
  assert_jaba_error "Error at #{src_loc('A948BC7B')}: Cannot instance undefined type ':undefined'." do
    jaba(barebones: true) do
      undefined :a # A948BC7B
    end
  end
end

jtest 'supports per-type defaults' do
  jaba(barebones: true) do
    type :test do
      attr :a
      attr_array :b do
        default [1]
      end
    end
    defaults :test do # automatically included by all 'test' definitions
      a 1
      b [2]
    end
    shared :test_common do
      b [3]
    end
    test :t1 do
      include :test_common # Defaults are applied before includes
      a.must_equal 1
      b.must_equal [1, 2, 3]
    end
    test :t2 do
      include :test_common
      a 4
      b [4]
      a.must_equal 4
      b.must_equal [1, 2, 3, 4]
    end
  end
end

jtest 'supports include statement' do
  # TODO
  # TODO: test include by glob
end
