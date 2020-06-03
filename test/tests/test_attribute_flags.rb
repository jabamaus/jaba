# frozen_string_literal: true

module JABA

  using JABACoreExt

  class TestAttributeFlags < JabaTest

    it 'detects multiply defined flags' do
      check_fail "Attribute flag ':a' multiply defined", trace: [__FILE__, 'tagA'] do
        jaba do
          attr_flag :a
          attr_flag :a # tagA
        end
      end
    end

  end

end
