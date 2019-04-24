module JABA

class TestBoolAttribute < JabaTestCase

  describe 'BoolAttribute' do
    
    it 'defaults to false' do
      jaba do
        attr :a do
          type :bool
        end
        project
      end
    end
    
    it 'requires a default of true or false' do
    end
    
    it 'supports boolean accessor when reading' do
    end
    
    it 'rejects boolean accessor on non-boolean properties' do
    end
    
  end
  
end

end
