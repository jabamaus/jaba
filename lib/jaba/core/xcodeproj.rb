# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class XcodeProj < Project
  
    ##
    #
    def init
      @host = @attrs.host_ref
    end

  end

end
