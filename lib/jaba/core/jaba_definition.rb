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
    attr_reader :source_location
    
    ##
    #
    def initialize(id, block, source_location)
      @id = id
      @block = block
      @source_location = source_location
      i = @source_location.rindex(':in') # Remove unwanted ':in' string
      @source_location.slice!(i..-1)
    end

    ##
    # Given a path in ruby 'backtrace' format, eg dir/file.rb:12, returns file.rb:12. Can't use the usual File.basename as it
    # strips the :12. Used in error messages.
    #
    def src_loc_basename
      @source_location.last_path_component
    end

  end

  ##
  #
  class JabaTypeDefinition < JabaDefinition

    attr_reader :defaults_definition

    ##
    #
    def initialize(id, block, source_location)
      super(id, block, source_location)
      
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
    
    include HookMethods

    attr_reader :jaba_type_id
    attr_reader :jaba_type
    attr_reader :source_dir

    ##
    #
    def initialize(id, jaba_type_id, block, source_location)
      super(id, block, source_location)
      
      @jaba_type_id = jaba_type_id
      @jaba_type = nil
      @source_file = @source_location[/^(.+):\d/, 1]
      @source_dir = @source_file.dirname

      define_hook(:generate)
    end

  end

end
