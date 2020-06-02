# frozen_string_literal: true

require 'fiddle'

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  module OS
    
    ##
    #
    def self.windows?
      true
    end
    
    ##
    #
    def self.mac?
      false
    end
    
    ##
    #
    def self.generate_guid
      if windows?
        result = ' ' * 16
        rpcrt4 = Fiddle.dlopen('rpcrt4.dll')
        uuid_create = Fiddle::Function.new(rpcrt4['UuidCreate'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_LONG)
        uuid_create.call(result)
        sprintf('{%04X%04X-%04X-%04X-%04X-%04X%04X%04X}', *result.unpack('SSSSSSSS')).upcase
      else
        raise 'generate_guid not implemented on this platform'
      end
    end
    
  end

end
