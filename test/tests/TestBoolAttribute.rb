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
      # TODO: remove hard coded absolute path
      check_fails(msg: 'Default must be boolean', file: "C:/projects/GitHub/jaba/lib/jaba/core/Types.rb", line: "raise 'Default must be boolean'",
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
    
    it 'supports boolean accessor when reading' do
      jaba do
        extend :text do
          attr :c do
            type :bool
            default true
          end
        end
        text :b do
          c.must_equal(true)
          c?.must_equal(true)
          c false
          c.must_equal(false)
          c?.must_equal(false)
        end
      end
    end
    
    it 'rejects boolean accessor on non-boolean properties' do
    end
    
  end
  
end

end
