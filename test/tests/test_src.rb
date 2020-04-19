# frozen_string_literal: true

module JABA

  class TestSrc < JabaTest

    it 'can be specified explicitly' do
      r = temp_dir
      make_file('a.cpp')
      jaba do
        #cpp :app do
        #  root r
        #  src ['a.cpp']
        #end
      end

    end

  end

end
