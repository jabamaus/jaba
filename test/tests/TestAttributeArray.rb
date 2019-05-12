module JABA

class TestAttributeArray < JabaTest

  it 'strips duplicates by default' do
    op = jaba do
      define :test do
        attr :a do
          flags :array
        end
      end
      test :t do
        a [5, 5, 6, 6, 7, 7, 7]
        a.must_equal [5, 5, 6, 6, 7, 7, 7]
        generate do
          a.must_equal [5, 6, 7]
        end
      end
    end
    #op.warnings.must_equal(["Warning at TestAttributeArray.rb:6: 'a' array attribute contains duplicates"]) # TODO: turn into check_warn util
  end
  
end

end
