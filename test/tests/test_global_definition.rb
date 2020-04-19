# frozen_string_literal: true

module JABA

  class TestGlobalDefinition < JabaTest

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
                  "(underscore permitted), eg :my_id or 'my_id'", trace: [__FILE__, '# tag1'] do
        jaba do
          shared 'Space invalid' do # tag1
          end
        end
      end
      
      check_fail "'1' is an invalid id", trace: [__FILE__, '# tag2'] do
        jaba do
          shared 1 # tag2
        end
      end
    end
    
    it 'detects duplicate ids with definitions of the same type' do
      check_fail "'a' multiply defined", trace: [__FILE__, '# tag3'] do
        jaba do
          shared :a do
          end
          shared :a do # tag3
          end
        end
      end

      check_fail "'b' multiply defined", trace: [__FILE__, '# tag4'] do
        jaba do
          text :b
          text :b # tag4
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
    
    it 'allows id to be accessed from definitions' do
      jaba do
        define :test
        test :a do
          id.must_equal(:a)
        end
      end
    end

    it 'rejects attempts to instance an unknown type' do
      check_fail "'undefined' type not defined", trace: [__FILE__, '# tag6'] do
        jaba do
          undefined :a # tag6
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
      check_fail "'test' defaults multiply defined", trace: [__FILE__, '# tagI'] do
        jaba do
          define :test
          defaults :test
          defaults :test # tagI
        end
      end
    end

  end

end
