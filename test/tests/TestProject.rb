module JABA

class TestProject < JabaTest

  it 'is evaluated per-type, per-sku and per-target' do
    jaba do
      project :p do
        skus [:win32_vs2017, :x64_vs2017]
        targets [:t1, :t2]
        generate do
          
        end
      end
    end
  end
  
end

end
