# frozen_string_literal: true

module JABA

  class TestJabaNode < JabaTest

    it 'can be inspected' do
      s = Services.new
      s.input.definitions do
        define :test do
          attr :a, type: :bool
        end
        test :t do
          a.must_equal(false)
        end
      end
      s.run
      nodes = s.instance_variable_get(:@nodes)
      nodes.inspect
    end

  end

end