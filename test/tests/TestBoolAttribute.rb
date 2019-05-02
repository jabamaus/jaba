module JABA

class TestBoolAttribute < JabaTest

  describe 'BoolAttribute' do
    
    it 'defaults to false' do
    end
    
    it 'requires a default of true or false' do
    end
    
    it 'supports boolean accessor when reading' do
      jaba do
        extend :text do
          attr :enabled do
            type :bool
            default true
          end
        end
        text :b do
          enabled.must_equal(true)
          enabled?.must_equal(true)
          enabled false
          enabled.must_equal(false)
          enabled?.must_equal(false)
        end
      end
    end
    
    it 'rejects boolean accessor on non-boolean properties' do
    end
    
  end
  
end

end
