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
    
    check_fails("'Space invalid' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'", trace: [__FILE__, '# tag1']) do
      jaba do
        shared 'Space invalid' do # tag1
        end
      end
    end
    
    check_fails("'1' is an invalid id", trace: [__FILE__, '# tag2']) do
      jaba do
        shared 1 do # tag2
        end
      end
    end
  end
  
  it 'detects duplicate ids with definitions of the same type' do
    check_fails("'a' multiply defined", trace: [__FILE__, '# tag3']) do
      jaba do
        shared :a do
        end
        shared :a do # tag3
        end
      end
    end

    check_fails("'b' multiply defined", trace: [__FILE__, '# tag4']) do
      jaba do
        project :b do
        end
        project :b do # tag4
        end
      end
    end
    
    check_fails("'c' multiply defined", trace: [__FILE__, '# tag5']) do
      jaba do
        category :c do
        end
        category :c do # tag5
        end
      end
    end
  end

  it 'allows different types to have the same id' do
    jaba do
      shared :a do
      end
      project :a do
        platforms [:win32]
        targets [:t]
      end
      workspace :a do
      end
    end
  end
  
  it 'rejects attempts to instance an unknown type' do
    check_fails("'undefined' type is not defined. Cannot instance", trace: [__FILE__, '# tag6']) do
      jaba do
        undefined :a do # tag6
        end
      end
    end
  end
  
end

end
