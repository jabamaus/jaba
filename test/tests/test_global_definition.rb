# frozen_string_literal: true

module JABA

  class TestGlobalDefinition < JabaTest

    it 'rejects invalid ids' do
      jaba do
        shared :Alpha_Num3r1cs_With_Underscores_Are_Valid_Everything_Else_Is_Not
        shared 'Str1ngs_also_allowed'
        shared 'this.is.valid'
      end
      
      check_fail "'Space invalid' is an invalid id. Must be an alphanumeric string or symbol " \
                  "(underscore permitted), eg :my_id or 'my_id'", trace: [__FILE__, '# tag1'] do
        jaba do
          shared 'Space invalid' # tag1
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
          shared :a
          shared :a # tag3
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
        shared :a
        workspace :a
      end
    end
    
    it 'rejects attempts to instance an unknown type' do
      check_fail "'undefined' type is not defined. Cannot instance", trace: [__FILE__, '# tag6'] do
        jaba do
          undefined :a # tag6
        end
      end
    end
    
  end

end
