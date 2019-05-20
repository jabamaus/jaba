module JABA

class TestAttributeDefinition < JabaTest

  it 'requires attribute id to be a symbol' do
    check_fails('\'attr\' attribute id must be specified as a symbol', backtrace: [[__FILE__, '# tag1']]) do
      jaba do
        extend :project do
          attr 'attr' do # tag1
          end
        end
      end
    end
  end
  
  it 'requires a block to be supplied' do
    check_fails("'b' attribute requires a block", backtrace: [[__FILE__, '# tag2']]) do
      jaba do
        extend :project do
          attr :b # tag2
        end
      end
    end
  end
  
  it 'detects duplicate attribute ids' do
    check_fails("'a' attribute multiply defined", backtrace: [[__FILE__, '# tag3']]) do
      jaba do
        extend :project do
          attr :a do
          end
          attr :a do # tag3
          end
        end
      end
    end
  end
  
end

end
