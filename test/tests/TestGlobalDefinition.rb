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
    
    check_fails("'Space invalid' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'", backtrace: [[__FILE__, "shared 'Space invalid'"]]) do
      jaba do
        shared 'Space invalid' do
        end
      end
    end
    
    check_fails("'1' is an invalid id", backtrace: [[__FILE__, 'shared 1 do']]) do
      jaba do
        shared 1 do
        end
      end
    end
  end
  
  it 'detects duplicate ids with definitions of the same type' do
    check_fails("'a' multiply defined", backtrace: [[__FILE__, 'shared :a do # this one']]) do
      jaba do
        shared :a do
        end
        shared :a do # this one
        end
      end
    end

    check_fails("'b' multiply defined", backtrace: [[__FILE__, 'project :b do # this one']]) do
      jaba do
        project :b do
        end
        project :b do # this one
        end
      end
    end
    
    check_fails("'c' multiply defined", backtrace: [[__FILE__, 'category :c do # this one']]) do
      jaba do
        category :c do
        end
        category :c do # this one
        end
      end
    end
  end

  it 'allows different types to have the same id' do
    jaba do
      shared :a do
      end
      project :a do
        skus [:win32_vs2017]
        targets [:t]
      end
      workspace :a do
      end
    end
  end
  
  it 'rejects attempts to instance an unknown type' do
    check_fails("'undefined' type is not defined. Cannot instance", backtrace: [[__FILE__, 'undefined :a']]) do
      jaba do
        undefined :a do
        end
      end
    end
  end
  
end

end
