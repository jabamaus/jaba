# frozen_string_literal: true

module JABA

  class TestInputManager < JabaTest

    describe 'failure conditions' do
      
      # TODO: should duplicate array options be allowed?
      it 'detects duplicate options' do
        #check_fail '--dry-run specified more than once' do
          #jaba(barebones: true, argv: ['--dry-run', '--dry-run'])
        #end
      end

    end

    it 'can populate an instance from command line' do
      jaba(barebones: true, argv: ['--dry-run']) do
      end
    end

  end

end
