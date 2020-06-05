# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  # eg project/workspace/category etc.
  #
  class JabaType < JabaObject

    include PropertyMethods
    
    # The type id given to the jaba type in define() method, whether a top level type or a subtype.
    # Contrast this with definition_id which will return the top level type's id even if it is called
    # on a subtype.
    #
    attr_reader :handle
    attr_reader :attribute_defs
    attr_reader :dependencies
    attr_reader :generator
    
    ##
    #
    def initialize(services, definition, handle, generator)
      super(services, definition, JabaTypeAPI.new(self))

      @handle = handle
      @attribute_defs = []
      @generator = generator

      define_property(:help)
      define_array_property(:dependencies)
    end

    ##
    #
    def define_attr(id, variant, type: nil, &block)
      @services.log "  Defining '#{id}' attribute [variant=#{variant}, type=#{type}]"
      
      validate_id(id)
      id = id.to_sym
      
      db = JabaDefinition.new(id, block, caller(2, 1)[0])
      ad = JabaAttributeDefinition.new(@services, db, type, variant, self)
      
      @attribute_defs << ad

      @definition.register_attr_def(id, ad)
      ad  
    end

    ##
    #
    def define_sub_type(id, &block)
      @services.make_type(id, @definition, sub_type: true, &block)
      @dependencies << id
    end

    ##
    #
    def to_s
      @handle.to_s
    end

    ##
    #
    def validate_id(id)
      if !(id.symbol? || id.string?) || id !~ /^[a-zA-Z0-9_\?]+$/
        jaba_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
          "(underscore permitted), eg :my_id or 'my_id'")
      end
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
