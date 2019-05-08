module JABA

class TestAttributeDefinition < JabaTest

  it 'requires attribute id to be a symbol' do
    check_fails(msg: '\'attr\' attribute id must be specified as a symbol', file: __FILE__, line: "attr 'attr' do") do
      jaba do
        extend :project do
          attr 'attr' do
          end
        end
      end
    end
  end
  
  it 'detects duplicate attribute ids' do
    check_fails(msg: "'a' attribute multiply defined", file: __FILE__, line: 'attr :a do # this one') do
      jaba do
        extend :project do
          attr :a do
          end
          attr :a do # this one
          end
        end
      end
    end
  end
  
end

end
