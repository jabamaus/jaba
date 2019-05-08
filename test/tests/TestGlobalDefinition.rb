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
    check_fails(msg: "'Space invalid' is an invalid id. Must be an alphanumeric string or symbol (underscore permitted), eg :my_id or 'my_id'", file: __FILE__, line: "shared 'Space invalid'") do
      jaba do
        shared 'Space invalid' do
        end
      end
    end
    
    check_fails(msg: "'1' is an invalid id", file: __FILE__, line: 'shared 1 do')  do
      jaba do
        shared 1 do
        end
      end
    end
  end
  
  it 'detects duplicate ids with definitions of the same type' do
    check_fails(msg: "'a' multiply defined", file: __FILE__, line: 'shared :a do # this one') do
      jaba do
        shared :a do
        end
        shared :a do # this one
        end
      end
    end

    check_fails(msg: "'b' multiply defined", file: __FILE__, line: 'project :b do # this one') do
      jaba do
        project :b do
        end
        project :b do # this one
        end
      end
    end
    
    check_fails(msg: "'c' multiply defined", file: __FILE__, line: 'category :c do # this one') do
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
      end
      target :a do
      end
      workspace :a do
      end
    end
  end
  
end

end
