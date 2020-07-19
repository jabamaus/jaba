# frozen_string_literal: true

module JABA

  class TestJabaType < JabaTest

    it 'can be flagged as a singleton' do
      check_fail "singleton type 'test' must be instantiated exactly once", line: [__FILE__, 'tagA'] do
        jaba(barebones: true) do
          define :test do # tagA
            singleton true
          end
        end
      end
      check_fail "singleton type 'test' must be instantiated exactly once", line: [__FILE__, 'tagB'] do
        jaba(barebones: true) do
          define :test do
            singleton true
          end
          test :t1
          test :t2 # tagB
        end
      end
    end

  end

end
