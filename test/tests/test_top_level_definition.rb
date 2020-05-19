# frozen_string_literal: true

module JABA

  class TestTopLevelDefinition < JabaTest

    it 'rejects invalid ids' do
      jaba do
        shared :Alpha_Num3r1cs_With_Underscores_Are_Valid_Everything_Else_Is_Not do
        end
        shared 'Str1ngs_also_allowed' do
        end
        shared 'this.is.valid' do
        end
      end
      
      check_fail "'Space invalid' is an invalid id. Must be an alphanumeric string or symbol " \
                  "(underscore permitted), eg :my_id or 'my_id'", trace: [__FILE__, 'tagS'] do
        jaba do
          shared 'Space invalid' do # tagS
          end
        end
      end
      
      check_fail "'1' is an invalid id", trace: [__FILE__, 'tagZ'] do
        jaba do
          shared 1 do # tagZ
          end
        end
      end
    end
    
    it 'detects duplicate ids with definitions of the same type' do
      check_fail "'a' multiply defined", trace: [__FILE__, 'tagI'] do
        jaba do
          shared :a do
          end
          shared :a do # tagI
          end
        end
      end

      check_fail "'b' multiply defined", trace: [__FILE__, 'tagX'] do
        jaba do
          text :b
          text :b # tagX
        end
      end
    end

    it 'allows different types to have the same id' do
      jaba do
        shared :a do
        end
        workspace :a
      end
    end
    
    it 'allows definition id to be accessed from all definitions' do
      jaba do
        attr_type :v do
          _ID.must_equal(:v)
        end
        attr_flag :f do
          _ID.must_equal(:f)
        end
        define :test do
          _ID.must_equal(:test)
          attr :b do
            _ID.must_equal(:b)
          end
        end
        open :test do
          _ID.must_equal(:test)
        end
        defaults :test do
          _ID.must_equal(:a) # :a not :test
        end
        shared :s do
          _ID.must_equal(:a) # :a not :s
        end
        test :a do
          include :s
          _ID.must_equal(:a)
        end
      end
    end

    it 'rejects attempts to instance an unknown type' do
      check_fail "'undefined' type not defined", trace: [__FILE__, 'tagJ'] do
        jaba do
          undefined :a # tagJ
        end
      end
    end

    it 'supports per-type defaults' do
      jaba do
        define :test do
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

    it 'checks for multiply defined defaults' do
      check_fail "'test' defaults multiply defined", trace: [__FILE__, 'tagH'] do
        jaba do
          define :test
          defaults :test
          defaults :test # tagH
        end
      end
    end

  end

end
