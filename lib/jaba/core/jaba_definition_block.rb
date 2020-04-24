# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaDefinitionBlock

    attr_reader :definition_id
    attr_reader :block
    attr_reader :api_call_line
    
    ##
    #
    def initialize(id, block, api_call_line)
      @definition_id = id
      @block = block
      @api_call_line = api_call_line
    end

  end

end
