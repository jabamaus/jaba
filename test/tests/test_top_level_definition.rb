# frozen_string_literal: true

module JABA

  using JABACoreExt

  class TestTopLevelDefinition < JabaTest

    it 'rejects invalid ids' do
      jaba(barebones: true) do
        shared :Alpha_Num3r1cs_With_Underscores_Are_Valid_Everything_Else_Is_Not do
        end
        shared 'Str1ngs_also_allowed' do
        end
        shared 'this.is.valid' do
        end
        shared 'this-is-valid' do
        end
      end
      
      check_fail "'Space invalid' is an invalid id. Must be an alphanumeric string or symbol", line: [__FILE__, 'tagS'] do
        jaba(barebones: true) do
          shared 'Space invalid' do # tagS
          end
        end
      end
      
      check_fail "'1' is an invalid id", line: [__FILE__, 'tagZ'] do
        jaba(barebones: true) do
          shared 1 do # tagZ
          end
        end
      end
    end
    
    it 'detects duplicate ids with definitions of the same type' do
      [:cpp, :defaults, :type, :shared, :text, :workspace].each do |item|
        check_fail "'#{item}|:a' multiply defined. First definition at #{__FILE__.basename}:#{find_line_number(__FILE__, 'tagX')}.", line: [__FILE__, 'tagI'] do
          jaba do
            __send__(item, :a) do # tagX
            end
            __send__(item, :a) do # tagI
            end
          end
        end
      end
    end

    it 'allows different types to have the same id' do
      jaba(cpp_app: true, dry_run: true) do
        shared :a do
        end
        cpp :app do
          src ['a.cpp'], :force
        end
        workspace :a do
          projects [:app]
        end
      end
    end
    
    it 'allows definition id to be accessed from all definitions' do
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

    it 'instances types in order of definition' do
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

    it 'rejects attempts to instance an unknown type' do
      check_fail "'undefined' type not defined", line: [__FILE__, 'tagJ'] do
        jaba(barebones: true) do
          undefined :a # tagJ
        end
      end
    end

    it 'supports per-type defaults' do
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

    it 'supports include statement' do
      # TODO
    end
    
  end

end
