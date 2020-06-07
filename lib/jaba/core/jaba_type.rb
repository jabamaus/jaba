# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaType < JabaObject

    include PropertyMethods

    # The type id given to the jaba type in define() method, whether a top level type or a subtype.
    # Contrast this with definition_id which will return the top level type's id even if it is called
    # on a subtype.
    #
    attr_reader :handle
    attr_reader :attribute_defs

    ##
    #
    def initialize(services, definition, handle, parent)
      super(services, definition, JabaTypeAPI.new(self))

      @handle = handle
      @top_level_type = parent
      @attribute_defs = []

      define_property(:help)
    end

    ##
    #
    def to_s
      @handle.to_s
    end

    ##
    #
    def top_level_type
      @top_level_type
    end

    ##
    #
    def define_attr(id, variant, type: nil, &block)
      @services.log "  Defining '#{id}' attribute [variant=#{variant}, type=#{type}]"
      
      validate_id(id)
      id = id.to_sym
      
      db = JabaDefinition.new(id, block, caller_locations(2, 1)[0])
      ad = JabaAttributeDefinition.new(@services, db, type, variant, self)
      
      @attribute_defs << ad

      top_level_type.register_attr_def(id, ad)
      ad  
    end

    ##
    #
    def define_sub_type(id, &block)
      jaba_error("Sub type '#{handle.inspect_unquoted}' cannot have another subtype '#{id.inspect_unquoted}'")
    end

    ##
    #
    def validate_id(id)
      if !(id.symbol? || id.string?) || id !~ /^[a-zA-Z0-9_\?]+$/
        jaba_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
          "(underscore permitted), eg :my_id or 'my_id'")
      end
    end

  end

  ##
  # eg project/workspace/category etc.
  #
  class TopLevelJabaType < JabaType

    attr_reader :generator
    attr_reader :defaults_definition
    attr_reader :dependencies

    ##
    #
    def initialize(services, definition, handle, generator, defaults_definition)
      super(services, definition, handle, self)

      @generator = generator
      @defaults_definition = defaults_definition
      @attr_defs = {}

      define_array_property(:dependencies) # TODO: validate explicitly specified deps
    end

    ##
    #
    def top_level_type
      self
    end

    ##
    #
    def define_sub_type(id, &block)
      @services.make_type(id, @definition, parent: self, &block)
    end

    ##
    #
    def get_attr_def(id)
      @attr_defs[id]
    end

    ##
    #
    def register_attr_def(id, attr_def)
      if @attr_defs.key?(id)
        attr_def.jaba_error("'#{id}' attribute multiply defined in '#{definition_id}'")
      end
      @attr_defs[id] = attr_def
    end

    ##
    #
    def register_referenced_attributes
      to_register = []
      @attr_defs.each do |id, attr_def|
        if attr_def.reference?
          rt_id = attr_def.referenced_type
          if rt_id != definition_id
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
    def resolve_dependencies
      # Convert dependencies specified as ids to jaba type objects
      #
      @dependencies.uniq!
      @dependencies.map! {|dep| @services.get_jaba_type(dep)}
    end


  end

end
