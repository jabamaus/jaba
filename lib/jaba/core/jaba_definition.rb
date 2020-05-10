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
      @attr_defs = {}
    end

    ##
    #
    def register_attr_def(id, attr_def)
      if @attr_defs.key?(id)
        attr_def.jaba_error("'#{id}' attribute multiply defined in '#{@id}'")
      end
      @attr_defs[id] = attr_def
    end

    ##
    #
    def register_referenced_attributes
      to_register = []
      @attr_defs.each do |id, attr_def|
        if attr_def.type_id == :reference
          rt_id = attr_def.get_property(:referenced_type)  # TODO: remove get_property
          if rt_id != @id
            jt = attr_def.services.get_jaba_type(rt_id)
            jt.attribute_defs.each do |d|
              if d.has_flag?(:expose)
                to_register << d
              end
            end
          end
        end
      end
      to_register.each{|d| register_attr_def(d.definition_id, d)}
    end

    ##
    #
    def attr_valid?(id)
      @attr_defs.key?(id)
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
