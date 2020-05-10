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
    
    ##
    #
    def initialize(id, block, api_call_line)
      @id = id
      @block = block
      @api_call_line = api_call_line
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
          rt_id = attr_def.referenced_type
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
    def get_attr_def(id)
      @attr_defs[id]
    end

  end

  ##
  #
  class JabaInstanceDefinition < JabaDefinition
    
    attr_reader :jaba_type_id
    attr_reader :jaba_type
    attr_reader :source_file
    attr_reader :source_dir

    ##
    #
    def initialize(id, jaba_type_id, block, api_call_line)
      super(id, block, api_call_line)
      
      @jaba_type_id = jaba_type_id
      @jaba_type = nil
      @source_file = @api_call_line[/^(.+):\d/, 1]
      @source_dir = File.dirname(@source_file)
    end

  end

end
