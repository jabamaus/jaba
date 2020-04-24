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

  ##
  #
  class JabaInstanceDefinitionBlock < JabaDefinitionBlock
    
    attr_reader :jaba_type_id
    attr_reader :jaba_type

    ##
    #
    def initialize(id, jaba_type_id, block, api_call_line)
      super(id, block, api_call_line)
      
      @jaba_type_id = jaba_type_id
      @jaba_type = nil

    end

  end

end
