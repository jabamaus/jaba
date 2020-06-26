# frozen_string_literal: true

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
    
  end

  ##
  #
  def self.generate_guid(namespace:, name:, braces: true)
    sha1 = ::Digest::SHA1.new
    sha1 << namespace << name
    a = sha1.digest.unpack("NnnnnN")
    a[2] = (a[2] & 0x0FFF) | (5 << 12)
    a[3] = (a[3] & 0x3FFF) | 0x8000
    uuid = "%08x-%04x-%04x-%04x-%04x%08x" % a
    uuid.upcase!
    uuid = "{#{uuid}}" if braces
    uuid.freeze
    uuid
  end

  ##
  #
  def self.milli_timer
    start_time = Time.now
    yield
    duration = Time.now - start_time
    millis = (duration * 1000).round(0)
    "#{millis}ms"
  end

end
