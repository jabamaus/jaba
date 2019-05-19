module JABA

class TestChoiceAttribute < JabaTest

    it 'requires items to be set' do
      check_fails("'items' must be set", backtrace: [[__FILE__, 'attr :a, type: :choice']]) do
        jaba do
          define :test do
            attr :a, type: :choice do
            end
          end
        end
      end
    end

end

end
