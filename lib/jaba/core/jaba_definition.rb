# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaDefinition

    attr_reader :id
    attr_reader :block
    attr_reader :api_call_line
    attr_reader :source_file
    
    ##
    #
    def initialize(id, block, api_call_line)
      @id = id
      @block = block
      @api_call_line = api_call_line
      @source_file = @api_call_line[/^(.+):\d/, 1]
    end

  end

  ##
  #
  class JabaTypeDefinition < JabaDefinition

    attr_reader :defaults_definition

    ##
    #
    def initialize(id, block, api_call_line)
      super(id, block, api_call_line)
      
      @defaults_definition = nil

    end

  end

  ##
  #
  class JabaInstanceDefinition < JabaDefinition
    
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
