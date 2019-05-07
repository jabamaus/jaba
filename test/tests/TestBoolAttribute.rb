module JABA

class TestBoolAttribute < JabaTest

  describe 'BoolAttribute' do
    
    it 'defaults to false' do
      jaba do
        extend :text do
          attr :a do
            type :bool
          end
        end
        text :t do
          a.must_equal(false)
        end
      end
    end
    
    it 'requires a default of true or false' do
      check_fails(msg: ':bool attributes only accept [true|false]', file: CoreTypesFile, line: "raise ':bool attributes only accept [true|false]'",
                  backtrace: ["#{__FILE__}:#{find_line_number('attr :b do', __FILE__)}"]) do
        jaba do
          extend :text do
            attr :b do
              type :bool
              default 1
            end
          end
        end
      end
    end
    
    it 'only allows boolean values' do
      check_fails(msg: ':bool attributes only accept [true|false]', file: CoreTypesFile, line: "raise ':bool attributes only accept [true|false]'",
                  backtrace: ["#{__FILE__}:#{find_line_number('c 1', __FILE__)}"]) do
        jaba do
          extend :text do
            attr :c do
              type :bool
              default true
            end
          end
          text :b do
            c 1
          end
        end
      end
    end
    
    it 'supports boolean accessor when reading' do
      jaba do
        extend :text do
          attr :d do
            type :bool
            default true
          end
        end
        text :b do
          d.must_equal(true)
          d?.must_equal(true)
          d false
          d.must_equal(false)
          d?.must_equal(false)
        end
      end
    end
    
    it 'rejects boolean accessor on non-boolean properties' do
      check_fails(msg: "'e' attribute is not of type :bool", file: __FILE__, line: 'if e?') do
        jaba do
          extend :text do
            attr :e do
              type :file
            end
          end
          text :a do
            if e?
            end
          end
        end
      end
    end
    
  end
  
end

end
